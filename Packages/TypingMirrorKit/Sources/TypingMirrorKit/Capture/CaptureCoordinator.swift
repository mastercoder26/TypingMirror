import AppKit
import Carbon.HIToolbox
import Foundation
import Observation

/// Ties the event tap, segmenter and store together.
///
/// The ring buffer is drained on a timer rather than signalled from the callback:
/// at keystroke volumes a poll costs nothing, while waking the consumer from the
/// tap would add a syscall to the hot path for no benefit.
@MainActor
@Observable
public final class CaptureCoordinator {
    public enum State: Equatable {
        case stopped
        case needsPermission
        case running
    }

    public private(set) var state: State = .stopped
    public private(set) var liveKeystrokeCount = 0
    public private(set) var droppedEventCount = 0
    public private(set) var tapResetCount = 0
    public private(set) var isSecureInputActive = false
    /// Keystrokes in the session currently being recorded.
    public private(set) var openSegmentKeystrokes = 0
    public private(set) var lastSavedAt: Date?

    /// Not observed, for the same reason as the speed test's buffer: the live
    /// graph reads it on the display's schedule and typing must not invalidate
    /// any view.
    public let rhythm = RhythmBuffer()

    private let runner = EventTapRunner()
    private let timebase = TimebaseConverter()
    private let store: SessionStore
    private var segmenter = SessionSegmenter()
    private var drainTask: Task<Void, Never>?
    private var retryTask: Task<Void, Never>?
    private var lastTimestampMs: Double?
    private var lastWallClock: Date?
    private var wordPosition: UInt8 = 0
    private var settings: CaptureSettings

    public var onSessionSaved: (@MainActor (SessionRecord) -> Void)?

    public init(store: SessionStore, settings: CaptureSettings) {
        self.store = store
        self.settings = settings
    }

    public func update(settings: CaptureSettings) {
        self.settings = settings
        if settings.isGlobalCaptureEnabled {
            start()
        } else {
            stop()
        }
    }

    public func start() {
        guard state != .running else { return }
        guard runner.start() else {
            // A nil tap is the only reliable signal that permission is missing;
            // the trust APIs have been inconsistent across releases.
            state = .needsPermission
            startRetrying()
            return
        }
        state = .running
        stopRetrying()
        startDraining()
    }

    /// Retries tap creation until it succeeds.
    ///
    /// Without this, granting permission does nothing until the app is relaunched
    /// — the user flips the switch, returns, and the app still says it cannot see
    /// anything.
    private func startRetrying() {
        guard retryTask == nil else { return }
        retryTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard let self, self.state == .needsPermission else { return }
                guard self.settings.isGlobalCaptureEnabled else { continue }
                if self.runner.start() {
                    self.state = .running
                    self.stopRetrying()
                    self.startDraining()
                    return
                }
            }
        }
    }

    private func stopRetrying() {
        retryTask?.cancel()
        retryTask = nil
    }

    /// Asks for both permissions and begins watching for the grant.
    public func requestPermission() {
        CapturePermissions.requestAll()
        start()
    }

    public func stop() {
        stopRetrying()
        drainTask?.cancel()
        drainTask = nil
        runner.stop()
        Task { await flushOpenSegment() }
        state = .stopped
    }

    private func startDraining() {
        drainTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(250))
                guard let self else { return }
                await self.drain()
            }
        }
    }

    private func drain() async {
        // An open session has to be closed by the clock, not by the next
        // keystroke: otherwise nothing is ever written while you sit idle, and
        // the session you just typed appears only when you start the next one.
        if !segmenter.isEmpty, let last = lastWallClock,
           Date().timeIntervalSince(last) * 1000 > MetricConstants.sessionBreakMs {
            await flushOpenSegment()
        }

        let raw = runner.ring.drain()
        droppedEventCount = runner.ring.droppedCount
        tapResetCount = runner.resetCount

        // While a password field has focus macOS does not deliver keystrokes to
        // taps at all. Recording the transition keeps the timeline honest rather
        // than silently joining the two sides of the gap.
        let secure = IsSecureEventInputEnabled()
        if secure != isSecureInputActive {
            isSecureInputActive = secure
            markGap()
        }

        guard !raw.isEmpty else { return }

        let frontmost = NSWorkspace.shared.frontmostApplication
        let bundleID = frontmost?.bundleIdentifier
        guard settings.allows(bundleID: bundleID) else {
            markGap()
            return
        }

        let appName = frontmost?.localizedName
        let category = AppCategoryRules.category(for: bundleID)

        for event in raw {
            guard !event.isRepeat else { continue }
            let ms = timebase.milliseconds(fromTicks: event.timestampTicks)
            let interval = lastTimestampMs.map { ms - $0 } ?? 0
            lastTimestampMs = ms

            let keyClass = KeyClass(rawValue: event.keyClass) ?? .unknown
            updateWordPosition(for: keyClass)
            rhythm.record(atMs: ms)
            liveKeystrokeCount += 1
            lastWallClock = Date()

            let typingEvent = TypingEvent(
                intervalMs: max(0, interval),
                keyClass: keyClass,
                wordPosition: wordPosition
            )

            if let segment = segmenter.accept(
                event: typingEvent,
                at: Date(),
                appName: appName,
                category: category
            ) {
                await persist(segment)
            }
        }
        openSegmentKeystrokes = segmenter.count
    }

    private func updateWordPosition(for keyClass: KeyClass) {
        switch keyClass {
        case .space, .returnEnter, .tab: wordPosition = 0
        case .backspace: wordPosition = wordPosition > 0 ? wordPosition - 1 : 0
        default: wordPosition = min(wordPosition &+ 1, 255)
        }
    }

    private func markGap() {
        _ = segmenter.accept(
            event: TypingEvent(intervalMs: 0, keyClass: .gapSentinel),
            at: Date(),
            appName: nil,
            category: .mixed
        )
        lastTimestampMs = nil
    }

    private func flushOpenSegment() async {
        lastWallClock = nil
        lastTimestampMs = nil
        openSegmentKeystrokes = 0
        guard let segment = segmenter.close() else { return }
        await persist(segment)
    }

    private func persist(_ segment: SessionSegmenter.Segment) async {
        do {
            if let record = try await store.save(
                events: segment.events,
                startedAt: segment.startedAt,
                category: segment.category,
                appName: segment.appName,
                source: .global
            ) {
                lastSavedAt = Date()
                onSessionSaved?(record)
            }
        } catch {
            // A failed write must not take down capture; the next segment still
            // has a chance to persist.
            NSLog("TypingMirror: failed to save session — \(error.localizedDescription)")
        }
    }
}

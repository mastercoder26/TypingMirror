import CoreGraphics
import Foundation

/// Owns the CGEventTap and its dedicated run loop.
///
/// The tap runs on its own thread rather than the main run loop: a long layout
/// pass on the main thread would starve the callback and macOS would disable the
/// tap with `kCGEventTapDisabledByTimeout`, which is the most common way
/// tap-based capture silently stops working.
final class EventTapRunner: @unchecked Sendable {
    let ring: KeyEventRingBuffer

    private var machPort: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var runLoop: CFRunLoop?
    private var thread: Thread?
    private var classTable = KeyClassTable.forCurrentInputSource()
    private let lock = NSLock()
    private var _resetCount = 0
    private var _lastInstallSucceeded = false

    var resetCount: Int {
        lock.lock(); defer { lock.unlock() }
        return _resetCount
    }

    private var lastInstallSucceeded: Bool {
        get {
            lock.lock(); defer { lock.unlock() }
            return _lastInstallSucceeded
        }
        set {
            lock.lock(); defer { lock.unlock() }
            _lastInstallSucceeded = newValue
        }
    }

    init(ring: KeyEventRingBuffer = KeyEventRingBuffer()) {
        self.ring = ring
    }

    /// Returns false when the tap could not be created, which in practice means
    /// the required permission has not been granted.
    func start() -> Bool {
        guard thread == nil else { return true }

        let ready = DispatchSemaphore(value: 0)
        lastInstallSucceeded = false

        let thread = Thread { [weak self] in
            guard let self else { ready.signal(); return }
            self.runLoop = CFRunLoopGetCurrent()
            let didInstall = self.install()
            self.lastInstallSucceeded = didInstall
            ready.signal()
            guard didInstall else { return }
            while !Thread.current.isCancelled {
                CFRunLoopRunInMode(.defaultMode, 1.0, false)
            }
        }
        thread.name = "com.typingmirror.eventtap"
        thread.qualityOfService = .userInteractive
        self.thread = thread
        thread.start()
        ready.wait()

        let didInstall = lastInstallSucceeded
        if !didInstall { self.thread = nil }
        return didInstall
    }

    func stop() {
        thread?.cancel()
        if let machPort { CGEvent.tapEnable(tap: machPort, enable: false) }
        if let runLoop, let runLoopSource {
            CFRunLoopRemoveSource(runLoop, runLoopSource, .commonModes)
            CFRunLoopStop(runLoop)
        }
        machPort = nil
        runLoopSource = nil
        runLoop = nil
        thread = nil
    }

    func rebuildClassTable() {
        classTable = KeyClassTable.forCurrentInputSource()
    }

    private func install() -> Bool {
        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

        guard let port = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            // Listen only: the tap can never drop or alter the user's input, and a
            // slow callback can never delay a keystroke reaching its app.
            place: .tailAppendEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: eventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return false
        }

        machPort = port
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: port, enable: true)
        return true
    }

    /// The hot path. No allocation, no locks beyond the ring's, no Foundation,
    /// and no Swift concurrency — entering an executor from here would add
    /// unbounded latency to every keystroke the system delivers.
    fileprivate func handle(type: CGEventType, event: CGEvent) {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            // Re-enabling is mandatory: this fires after sleep, after a CPU stall,
            // and sometimes for no visible reason. Without it capture stops dead.
            if let machPort { CGEvent.tapEnable(tap: machPort, enable: true) }
            lock.lock(); _resetCount += 1; lock.unlock()
            return
        case .keyDown:
            break
        default:
            return
        }

        let keyCode = UInt16(truncatingIfNeeded: event.getIntegerValueField(.keyboardEventKeycode))
        let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
        let flags = event.flags
        let hasCommandOrControl = flags.contains(.maskCommand) || flags.contains(.maskControl)

        let keyClass = classTable.classify(keyCode: keyCode, hasCommandOrControl: hasCommandOrControl)

        ring.tryPush(
            RawKeyEvent(
                timestampTicks: event.timestamp,
                keyClass: keyClass.rawValue,
                isRepeat: isRepeat
            )
        )
    }
}

/// A global `let` holding a C function pointer is `Sendable`, which keeps this
/// bridge clean under strict concurrency.
private let eventTapCallback: CGEventTapCallBack = { _, type, event, userInfo in
    if let userInfo {
        Unmanaged<EventTapRunner>.fromOpaque(userInfo)
            .takeUnretainedValue()
            .handle(type: type, event: event)
    }
    return Unmanaged.passUnretained(event)
}

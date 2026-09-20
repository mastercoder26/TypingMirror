import SwiftUI
import TypingMirrorKit

/// A blank surface that records a real session while you write whatever you like.
///
/// Nothing typed here is retained: keystrokes become timing and key class, and
/// the text is discarded when the view goes away.
struct PracticePadView: View {
    @Environment(AppModel.self) private var model

    @State private var events: [TypingEvent] = []
    @State private var startedAt: Date?
    @State private var lastTimestamp: TimeInterval?
    @State private var characterCount = 0
    @State private var isActive = true
    @State private var saveMessage: String?
    @State private var estimator = LiveRhythmEstimator()
    @State private var liveWPM = 0.0

    private let rhythm = RhythmBuffer()

    var body: some View {
        VStack(alignment: .leading, spacing: Tk.S.s6) {
            header
            figures
            surface
            graph
            footer
        }
        .padding(.horizontal, Tk.S.s7)
        .padding(.vertical, Tk.S.s6)
        .frame(maxWidth: Tk.L.contentMaxWidth, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            KeystrokeCaptureView(isActive: isActive) { handle($0) }
                .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onTapGesture { isActive = true }
        .task { rhythm.reset() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Tk.S.s1) {
            Text("Practice pad")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Tk.C.textPrimary)
            Text("Type anything. Only the timing is kept — the words are not.")
                .font(Tk.F.body)
                .foregroundStyle(Tk.C.textTertiary)
        }
    }

    private var figures: some View {
        MetricRow {
            Metric("Speed", value: events.isEmpty ? "—" : Fmt.wpm(liveWPM), unit: "wpm", prominent: true)
            MetricDivider()
            Metric("Keystrokes", value: "\(events.count)")
            MetricDivider()
            Metric("Corrections", value: "\(events.count { $0.keyClass.isCorrection })")
            MetricDivider()
            Metric("Elapsed", value: Fmt.duration(ms: events.reduce(0) { $0 + $1.intervalMs }))
        }
    }

    /// A deliberately abstract stand-in for the text: one mark per keystroke, so
    /// there is visible feedback without the words existing anywhere.
    private var surface: some View {
        GlassPanel {
            Text(String(repeating: "·", count: min(characterCount, 600)))
                .font(Tk.F.stream)
                .foregroundStyle(Tk.C.textSecondary)
                .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
                .lineLimit(6)
        }
    }

    private var graph: some View {
        VStack(alignment: .leading, spacing: Tk.S.s2) {
            SectionHeader("Live rhythm", trailing: "taller is faster")
            LiveRhythmGraph(buffer: rhythm, height: 96)
        }
    }

    private var footer: some View {
        HStack(spacing: Tk.S.s3) {
            Button("Save session") { Task { await save() } }
                .accessibilityLabel("Save session")
                .buttonStyle(.glassProminent)
                .tint(Tk.C.accent)
                .foregroundStyle(Tk.C.bgBase)
                .disabled(events.count < MetricConstants.minimumKeystrokes)

            Button("Discard") { clear() }
                .buttonStyle(.glass)
                .accessibilityLabel("Discard")

            if let saveMessage {
                Text(saveMessage)
                    .font(Tk.F.caption)
                    .foregroundStyle(Tk.C.textTertiary)
            }

            Spacer()

            Text("\(MetricConstants.minimumKeystrokes) keystrokes minimum to save")
                .font(Tk.F.caption)
                .foregroundStyle(Tk.C.textTertiary)
        }
    }

    private func handle(_ keystroke: Keystroke) {
        guard !keystroke.isRepeat else { return }
        if startedAt == nil { startedAt = Date() }

        let interval = lastTimestamp.map { (keystroke.timestamp - $0) * 1000 } ?? 0
        lastTimestamp = keystroke.timestamp
        rhythm.record(atMs: keystroke.timestamp * 1000)

        let elapsed = events.reduce(0) { $0 + $1.intervalMs } + interval
        estimator.ingest(atMs: elapsed)
        liveWPM = estimator.instantaneousWPM(atMs: elapsed)

        let keyClass: KeyClass
        switch keystroke.kind {
        case .text(let character) where character == " ":
            keyClass = .space
            characterCount += 1
        case .text(let character):
            keyClass = character.isLetter ? .letter : (character.isNumber ? .digit : .punctuation)
            characterCount += 1
        case .backspace, .wordDelete:
            keyClass = .backspace
            characterCount = max(0, characterCount - 1)
        }

        events.append(
            TypingEvent(
                intervalMs: max(0, interval),
                keyClass: keyClass,
                wordPosition: UInt8(min(characterCount % 24, 255))
            )
        )
    }

    private func save() async {
        guard let startedAt else { return }
        await model.saveSession(
            events: events,
            startedAt: startedAt,
            category: .writing,
            source: .practicePad
        )
        saveMessage = "Saved."
        clear()
    }

    private func clear() {
        events = []
        startedAt = nil
        lastTimestamp = nil
        characterCount = 0
        liveWPM = 0
        estimator = LiveRhythmEstimator()
        rhythm.reset()
    }
}

import SwiftUI
import TypingMirrorKit

struct SpeedTestView: View {
    @Environment(AppModel.self) private var model
    @State private var engine = SpeedTestEngine()
    @State private var isFocused = true

    var body: some View {
        VStack(alignment: .leading, spacing: Tk.S.s6) {
            header

            if engine.phase == .finished, let score = engine.score {
                SpeedTestResultsView(score: score, elapsedMs: engine.elapsedMs) {
                    engine.reset()
                    isFocused = true
                }
            } else {
                liveFigures
                stream
                liveGraph
                footer
            }
        }
        .padding(.horizontal, Tk.S.s7)
        .padding(.vertical, Tk.S.s6)
        .frame(maxWidth: Tk.L.contentMaxWidth, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            KeystrokeCaptureView(isActive: isFocused && engine.phase != .finished) {
                engine.handle($0)
            }
            .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
        .onAppear { isFocused = true }
        .onChange(of: engine.phase) { _, phase in
            guard phase == .finished else { return }
            Task { await persist() }
        }
    }

    /// A finished test is a real session, and its hesitations feed the word list
    /// when the lexical tier is on.
    private func persist() async {
        await model.saveSession(
            events: engine.recordedEvents,
            startedAt: engine.startedAt,
            category: .test,
            source: .typingTest
        )
        await model.recordHesitations(engine.hesitations)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Tk.S.s1) {
            Text("Speed test")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Tk.C.textPrimary)
            Text("\(engine.wordCount) words. Timing starts on your first keystroke.")
                .font(Tk.F.body)
                .foregroundStyle(Tk.C.textTertiary)
        }
    }

    private var liveFigures: some View {
        MetricRow {
            Metric(
                "Speed",
                value: engine.phase == .idle ? "—" : Fmt.wpm(engine.liveWPM),
                unit: "wpm",
                prominent: true
            )
            MetricDivider()
            Metric("Accuracy", value: "\(Fmt.percent(engine.liveAccuracy))", unit: "%")
            MetricDivider()
            Metric("Progress", value: "\(engine.wordIndex)/\(engine.wordCount)")
            MetricDivider()
            Metric("Elapsed", value: Fmt.duration(ms: engine.elapsedMs))
        }
    }

    private var stream: some View {
        WordStreamView(
            prompt: engine.prompt,
            typed: engine.typedSoFar,
            activeIndex: engine.wordIndex
        )
        .padding(.vertical, Tk.S.s4)
    }

    private var liveGraph: some View {
        VStack(alignment: .leading, spacing: Tk.S.s2) {
            SectionHeader("Live rhythm", trailing: "taller is faster")
            LiveRhythmGraph(buffer: engine.rhythm, height: 96)
        }
    }

    private var footer: some View {
        HStack(spacing: Tk.S.s3) {
            Button("Restart") {
                engine.reset()
                isFocused = true
            }
            .buttonStyle(.glass)
            .accessibilityLabel("Restart")

            if engine.phase == .running {
                Button("Finish now") { engine.finish() }
                    .buttonStyle(.glass)
                    .accessibilityLabel("Finish now")
            }

            Spacer()

            Text(model.settings.tier.storesText
                ? "Timing is stored. Long hesitations on safe words may also be kept."
                : "Nothing you type here is stored — only the timing between keys.")
                .font(Tk.F.caption)
                .foregroundStyle(Tk.C.textTertiary)
        }
    }
}

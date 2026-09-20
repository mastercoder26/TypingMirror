import SwiftUI
import TypingMirrorKit

struct SpeedTestView: View {
    @Environment(AppModel.self) private var model
    @State private var engine = SpeedTestEngine()
    @State private var isFocused = true

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.extraLarge) {
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
        .padding(.horizontal, Theme.Spacing.page)
        .padding(.vertical, Theme.Spacing.extraLarge)
        .frame(maxWidth: Theme.Layout.contentMaxWidth, alignment: .leading)
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
        VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
            Text("Speed test")
                .font(Theme.Typography.pageTitle)
                .foregroundStyle(Theme.Colors.primaryText)
            Text("\(engine.wordCount) words. Timing starts on your first keystroke.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.mutedText)
        }
    }

    private var liveFigures: some View {
        MetricRow {
            Metric(
                "Speed",
                value: engine.phase == .idle ? "—" : DisplayFormat.wpm(engine.liveWPM),
                unit: "wpm",
                prominent: true
            )
            MetricDivider()
            Metric("Accuracy", value: "\(DisplayFormat.percent(engine.liveAccuracy))", unit: "%")
            MetricDivider()
            Metric("Progress", value: "\(engine.wordIndex)/\(engine.wordCount)")
            MetricDivider()
            Metric("Elapsed", value: DisplayFormat.duration(ms: engine.elapsedMs))
        }
    }

    private var stream: some View {
        WordStreamView(
            prompt: engine.prompt,
            typed: engine.typedSoFar,
            activeIndex: engine.wordIndex
        )
        .padding(.vertical, Theme.Spacing.medium)
    }

    private var liveGraph: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            SectionHeader("Live rhythm", trailing: "taller is faster")
            LiveRhythmGraph(buffer: engine.rhythm, height: 96)
        }
    }

    private var footer: some View {
        HStack(spacing: Theme.Spacing.regular) {
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
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.mutedText)
        }
    }
}

import SwiftUI
import TypingMirrorKit

struct SpeedTestResultsView: View {
    let score: TestScore
    let elapsedMs: Double
    let onRestart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.extraLarge) {
            VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.small) {
                    Text(DisplayFormat.wpm(score.netWPM))
                        .font(Theme.Typography.headlineMetric)
                        .foregroundStyle(Theme.Colors.primaryText)
                    Text("WPM")
                        .font(Theme.Typography.title)
                        .foregroundStyle(Theme.Colors.secondaryText)
                }
                Text("Counting only the characters you got right.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.mutedText)
            }

            MetricRow {
                Metric("Accuracy", value: DisplayFormat.percent(score.accuracy), unit: "%")
                MetricDivider()
                Metric("Typed right first time", value: DisplayFormat.percent(score.rawAccuracy), unit: "%")
                MetricDivider()
                Metric("Wrong", value: "\(score.incorrectCharacters)")
                MetricDivider()
                Metric("Time", value: DisplayFormat.duration(ms: elapsedMs))
            }

            Text(commentary)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.secondaryText)

            Button("Run another") { onRestart() }
                .buttonStyle(.glassProminent)
                .tint(Theme.Colors.accent)
                .foregroundStyle(Theme.Colors.background)
        }
    }

    /// The gap between the two accuracy figures is the interesting part: it
    /// separates how often you erred from how much you left wrong.
    private var commentary: String {
        let fixed = score.accuracy - score.rawAccuracy
        if score.rawAccuracy >= 0.99 {
            return "Almost nothing to fix — you typed it right the first time."
        }
        if fixed > 0.04 {
            return "You made mistakes but caught most of them, "
                + "finishing \(DisplayFormat.percent(fixed)) points cleaner than you typed."
        }
        return "Most of what you mistyped stayed mistyped."
    }
}

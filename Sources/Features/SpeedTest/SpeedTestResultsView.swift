import SwiftUI
import TypingMirrorKit

struct SpeedTestResultsView: View {
    let score: TestScore
    let elapsedMs: Double
    let onRestart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Tk.S.s6) {
            VStack(alignment: .leading, spacing: Tk.S.s1) {
                HStack(alignment: .firstTextBaseline, spacing: Tk.S.s2) {
                    Text(Fmt.wpm(score.netWPM))
                        .font(.system(size: 76, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(Tk.C.textPrimary)
                    Text("WPM")
                        .font(Tk.F.title)
                        .foregroundStyle(Tk.C.textSecondary)
                }
                Text("Counting only the characters you got right.")
                    .font(Tk.F.body)
                    .foregroundStyle(Tk.C.textTertiary)
            }

            MetricRow {
                Metric("Accuracy", value: Fmt.percent(score.accuracy), unit: "%")
                MetricDivider()
                Metric("Typed right first time", value: Fmt.percent(score.rawAccuracy), unit: "%")
                MetricDivider()
                Metric("Wrong", value: "\(score.incorrectCharacters)")
                MetricDivider()
                Metric("Time", value: Fmt.duration(ms: elapsedMs))
            }

            Text(commentary)
                .font(Tk.F.body)
                .foregroundStyle(Tk.C.textSecondary)

            Button("Run another") { onRestart() }
                .buttonStyle(.glassProminent)
                .tint(Tk.C.accent)
                .foregroundStyle(Tk.C.bgBase)
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
                + "finishing \(Fmt.percent(fixed)) points cleaner than you typed."
        }
        return "Most of what you mistyped stayed mistyped."
    }
}

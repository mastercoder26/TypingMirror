import SwiftUI
import TypingMirrorKit

/// The session read-out.
///
/// Structure is editorial rather than dashboard-like: a stated headline, one
/// figure that matters, a hairline-separated band of supporting numbers, then the
/// rhythm itself. Glass appears once, around the rhythm, so it reads as a single
/// containment layer rather than cards inside cards.
struct SessionDetailView: View {
    let session: SessionRecord
    let index: Int
    var onReplay: () -> Void
    var onDelete: () -> Void

    private var metrics: SessionMetrics { session.metrics }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tk.S.s7) {
                header
                headline
                metricBand
                rhythmSection
                styleSection
                actions
            }
            .padding(.horizontal, Tk.S.s7)
            .padding(.vertical, Tk.S.s6)
            .frame(maxWidth: Tk.L.contentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Tk.S.s2) {
            Text("Session \(index)")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Tk.C.textPrimary)

            HStack(spacing: Tk.S.s2) {
                Text(session.category.displayName)
                if let appName = session.appName {
                    Text("·")
                    Text(appName)
                }
                Text("·")
                Text(Fmt.relativeDay(session.startedAt))
                Text(Fmt.clockTime(session.startedAt))
            }
            .font(Tk.F.body)
            .foregroundStyle(Tk.C.textSecondary)
        }
    }

    // MARK: Headline figure

    private var headline: some View {
        VStack(alignment: .leading, spacing: Tk.S.s1) {
            HStack(alignment: .firstTextBaseline, spacing: Tk.S.s2) {
                Text(Fmt.wpm(metrics.grossWPM))
                    .font(.system(size: 76, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(Tk.C.textPrimary)
                Text("WPM average")
                    .font(Tk.F.title)
                    .foregroundStyle(Tk.C.textSecondary)
            }
            Text("Measured over \(Fmt.duration(ms: metrics.activeMs)) of active typing. "
                + "\u{201C}Net of edits\u{201D} charges every backspace twice, so it is an estimate "
                + "rather than a measurement.")
                .font(Tk.F.body)
                .foregroundStyle(Tk.C.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Supporting numbers

    private var metricBand: some View {
        MetricRow {
            Metric("Session length", value: Fmt.duration(ms: metrics.wallMs))
            MetricDivider()
            Metric("Fastest burst", value: Fmt.wpm(metrics.peakBurstWPM), unit: "wpm")
            MetricDivider()
            Metric("Net of edits", value: Fmt.wpm(metrics.effectiveWPM), unit: "wpm")
            MetricDivider()
            Metric("Corrections", value: "\(metrics.correctionCount)")
            MetricDivider()
            Metric("Longest pause", value: Fmt.seconds(ms: metrics.longestPauseMs), unit: "s")
            MetricDivider()
            Metric("Keystrokes", value: "\(metrics.keystrokeCount)")
        }
    }

    // MARK: Rhythm

    private var rhythmSection: some View {
        VStack(alignment: .leading, spacing: Tk.S.s3) {
            SectionHeader("Rhythm", trailing: "taller is faster")
            GlassPanel {
                RhythmBar(samples: metrics.rhythm)
                    .padding(.vertical, Tk.S.s2)
            }
            Text(rhythmCaption)
                .font(Tk.F.body)
                .foregroundStyle(Tk.C.textTertiary)
        }
    }

    private var rhythmCaption: String {
        let pauses = metrics.pauseCount
        guard pauses > 0 else {
            return "You typed straight through without stopping for more than two seconds."
        }
        return "\(pauses) \(pauses == 1 ? "pause" : "pauses") of two seconds or more, "
            + "the longest running \(Fmt.seconds(ms: metrics.longestPauseMs)) seconds."
    }

    private var actions: some View {
        HStack(spacing: Tk.S.s3) {
            Button("Replay rhythm") { onReplay() }
                .buttonStyle(.glass)
                .accessibilityLabel("Replay rhythm")
                .disabled(!session.hasReplay)
            Button("Delete session", role: .destructive) { onDelete() }
                .buttonStyle(.glass)
                .accessibilityLabel("Delete session")
            Spacer()
        }
    }

    // MARK: Typing style

    private var styleSection: some View {
        VStack(alignment: .leading, spacing: Tk.S.s3) {
            SectionHeader("Typing style")

            if metrics.labels.isEmpty {
                Text("Not enough typing in this session to characterise a style.")
                    .font(Tk.F.body)
                    .foregroundStyle(Tk.C.textTertiary)
            } else {
                VStack(alignment: .leading, spacing: Tk.S.s3) {
                    ForEach(metrics.labels) { label in
                        StyleRow(
                            label: label,
                            explanation: PersonalityClassifier.explanation(
                                for: label, features: metrics.features
                            )
                        )
                    }
                }
            }
        }
    }
}

/// One style label with the reason it applied.
private struct StyleRow: View {
    let label: PersonalityLabel
    let explanation: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Tk.S.s3) {
            Image(systemName: label.symbol)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Tk.C.textSecondary)
                .frame(width: 18, alignment: .center)

            Text(label.title)
                .font(Tk.F.title)
                .foregroundStyle(Tk.C.textPrimary)

            Text(explanation)
                .font(Tk.F.body)
                .foregroundStyle(Tk.C.textTertiary)

            Spacer(minLength: 0)
        }
    }
}

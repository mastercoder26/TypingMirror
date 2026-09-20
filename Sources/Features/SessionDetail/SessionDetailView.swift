import SwiftUI
import TypingMirrorKit

/// Speed, rhythm and typing style for one saved session.
struct SessionDetailView: View {
    let session: SessionRecord
    let index: Int
    var onReplay: () -> Void
    var onDelete: () -> Void

    private var metrics: SessionMetrics { session.metrics }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.page) {
                header
                headline
                metricBand
                rhythmSection
                styleSection
                actions
            }
            .padding(.horizontal, Theme.Spacing.page)
            .padding(.vertical, Theme.Spacing.extraLarge)
            .frame(maxWidth: Theme.Layout.contentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text("Session \(index)")
                .font(Theme.Typography.pageTitle)
                .foregroundStyle(Theme.Colors.primaryText)

            HStack(spacing: Theme.Spacing.small) {
                Text(session.category.displayName)
                if let appName = session.appName {
                    Text("·")
                    Text(appName)
                }
                Text("·")
                Text(DisplayFormat.relativeDay(session.startedAt))
                Text(DisplayFormat.clockTime(session.startedAt))
            }
            .font(Theme.Typography.body)
            .foregroundStyle(Theme.Colors.secondaryText)
        }
    }

    // MARK: Headline figure

    private var headline: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.small) {
                Text(DisplayFormat.wpm(metrics.grossWPM))
                    .font(Theme.Typography.headlineMetric)
                    .foregroundStyle(Theme.Colors.primaryText)
                Text("WPM average")
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
            Text("Measured over \(DisplayFormat.duration(ms: metrics.activeMs)) of active typing. "
                + "\u{201C}Net of edits\u{201D} charges every backspace twice, so it is an estimate "
                + "rather than a measurement.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.mutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Supporting numbers

    private var metricBand: some View {
        MetricRow {
            Metric("Session length", value: DisplayFormat.duration(ms: metrics.wallMs))
            MetricDivider()
            Metric("Fastest burst", value: DisplayFormat.wpm(metrics.peakBurstWPM), unit: "wpm")
            MetricDivider()
            Metric("Net of edits", value: DisplayFormat.wpm(metrics.effectiveWPM), unit: "wpm")
            MetricDivider()
            Metric("Corrections", value: "\(metrics.correctionCount)")
            MetricDivider()
            Metric("Longest pause", value: DisplayFormat.seconds(ms: metrics.longestPauseMs), unit: "s")
            MetricDivider()
            Metric("Keystrokes", value: "\(metrics.keystrokeCount)")
        }
    }

    // MARK: Rhythm

    private var rhythmSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.regular) {
            SectionHeader("Rhythm", trailing: "taller is faster")
            GlassPanel {
                RhythmBar(samples: metrics.rhythm)
                    .padding(.vertical, Theme.Spacing.small)
            }
            Text(rhythmCaption)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.mutedText)
        }
    }

    private var rhythmCaption: String {
        let pauses = metrics.pauseCount
        guard pauses > 0 else {
            return "You typed straight through without stopping for more than two seconds."
        }
        return "\(pauses) \(pauses == 1 ? "pause" : "pauses") of two seconds or more, "
            + "the longest running \(DisplayFormat.seconds(ms: metrics.longestPauseMs)) seconds."
    }

    private var actions: some View {
        HStack(spacing: Theme.Spacing.regular) {
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
        VStack(alignment: .leading, spacing: Theme.Spacing.regular) {
            SectionHeader("Typing style")

            if metrics.labels.isEmpty {
                Text("Not enough typing in this session to characterise a style.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.mutedText)
            } else {
                VStack(alignment: .leading, spacing: Theme.Spacing.regular) {
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
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.regular) {
            Image(systemName: label.symbol)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.Colors.secondaryText)
                .frame(width: 18, alignment: .center)

            Text(label.title)
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.Colors.primaryText)

            Text(explanation)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.mutedText)

            Spacer(minLength: 0)
        }
    }
}

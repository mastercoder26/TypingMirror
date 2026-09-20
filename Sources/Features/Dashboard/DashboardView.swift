import Charts
import SwiftUI
import TypingMirrorKit

struct DashboardView: View {
    @Environment(AppModel.self) private var model
    let sessions: [SessionRecord]
    let days: [DailySummary]
    var onOpenSession: (SessionRecord.ID) -> Void

    private var today: DailySummary? { days.first }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.page) {
                header

                if let coordinator = model.coordinator, coordinator.state != .stopped {
                    LiveCaptureCard(coordinator: coordinator)
                }

                if sessions.isEmpty {
                    EmptyHint(
                        title: "Nothing recorded yet",
                        detail: "Type anywhere with watching turned on, run a speed test, or "
                            + "use the practice pad. A session is written once you pause for "
                            + "\(Int(MetricConstants.sessionBreakMs / 1000)) seconds."
                    )
                } else if let today {
                    todayBand(today)
                    fingerprintAndTrend(today)
                }

                if !sessions.isEmpty { recent }
            }
            .padding(.horizontal, Theme.Spacing.page)
            .padding(.vertical, Theme.Spacing.extraLarge)
            .frame(maxWidth: Theme.Layout.contentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
            Text("Today")
                .font(Theme.Typography.pageTitle)
                .foregroundStyle(Theme.Colors.primaryText)
            Text("How you have been typing, measured from timing alone.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.mutedText)
        }
    }

    private func todayBand(_ summary: DailySummary) -> some View {
        MetricRow {
            Metric("Average speed", value: DisplayFormat.wpm(summary.averageWPM), unit: "wpm", prominent: true)
            MetricDivider()
            Metric("Keystrokes", value: "\(summary.totalKeystrokes)")
            MetricDivider()
            Metric("Active", value: DisplayFormat.duration(ms: summary.totalActiveMs))
            MetricDivider()
            Metric("Sessions", value: "\(summary.sessionCount)")
        }
    }

    private func fingerprintAndTrend(_ summary: DailySummary) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.extraLarge) {
            VStack(alignment: .leading, spacing: Theme.Spacing.regular) {
                SectionHeader("Fingerprint")
                FingerprintView(
                    parameters: FingerprintParameters(vector: FingerprintVector(summary: summary))
                )
                .frame(width: 220, height: 220)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.regular) {
                SectionHeader("Speed by session", trailing: "most recent last")
                SpeedTrendChart(sessions: sessions.reversed())
            }
        }
    }

    private var recent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.regular) {
            SectionHeader("Recent sessions")
            VStack(spacing: 0) {
                ForEach(Array(sessions.enumerated()), id: \.element.id) { offset, session in
                    Button {
                        onOpenSession(session.id)
                    } label: {
                        RecentRow(session: session, index: sessions.count - offset)
                    }
                    .buttonStyle(.plain)

                    if offset < sessions.count - 1 {
                        Rectangle().fill(Theme.Colors.subtleBorder).frame(height: 1)
                    }
                }
            }
        }
    }
}

private struct RecentRow: View {
    let session: SessionRecord
    let index: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.medium) {
            Text("Session \(index)")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.primaryText)
                .frame(width: 96, alignment: .leading)

            Text(session.category.displayName)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.secondaryText)
                .frame(width: 96, alignment: .leading)

            RhythmBar(samples: session.metrics.rhythm, height: 26)
                .frame(maxWidth: .infinity)

            Text("\(DisplayFormat.wpm(session.metrics.grossWPM)) wpm")
                .font(Theme.Typography.smallMetric)
                .foregroundStyle(Theme.Colors.primaryText)
                .frame(width: 88, alignment: .trailing)
        }
        .padding(.vertical, Theme.Spacing.regular)
        .contentShape(Rectangle())
    }
}

/// Session speed in chronological order.
private struct SpeedTrendChart: View {
    let sessions: [SessionRecord]

    var body: some View {
        Chart(Array(sessions.enumerated()), id: \.element.id) { offset, session in
            LineMark(
                x: .value("Session", offset + 1),
                y: .value("Speed", session.metrics.grossWPM)
            )
            .foregroundStyle(Theme.Colors.secondaryText)
            .interpolationMethod(.monotone)

            PointMark(
                x: .value("Session", offset + 1),
                y: .value("Speed", session.metrics.grossWPM)
            )
            .foregroundStyle(Theme.Colors.primaryText)
            .symbolSize(28)
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine().foregroundStyle(Theme.Colors.subtleBorder)
                AxisValueLabel {
                    if let wpm = value.as(Double.self) {
                        Text(DisplayFormat.wpm(wpm))
                            .font(Theme.Typography.smallMonospaced)
                            .foregroundStyle(Theme.Colors.mutedText)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(Theme.Colors.subtleBorder.opacity(0.5))
            }
        }
        .frame(height: 220)
    }
}

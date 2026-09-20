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
            VStack(alignment: .leading, spacing: Tk.S.s7) {
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
            .padding(.horizontal, Tk.S.s7)
            .padding(.vertical, Tk.S.s6)
            .frame(maxWidth: Tk.L.contentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Tk.S.s1) {
            Text("Today")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Tk.C.textPrimary)
            Text("How you have been typing, measured from timing alone.")
                .font(Tk.F.body)
                .foregroundStyle(Tk.C.textTertiary)
        }
    }

    private func todayBand(_ summary: DailySummary) -> some View {
        MetricRow {
            Metric("Average speed", value: Fmt.wpm(summary.averageWPM), unit: "wpm", prominent: true)
            MetricDivider()
            Metric("Keystrokes", value: "\(summary.totalKeystrokes)")
            MetricDivider()
            Metric("Active", value: Fmt.duration(ms: summary.totalActiveMs))
            MetricDivider()
            Metric("Sessions", value: "\(summary.sessionCount)")
        }
    }

    private func fingerprintAndTrend(_ summary: DailySummary) -> some View {
        HStack(alignment: .top, spacing: Tk.S.s6) {
            VStack(alignment: .leading, spacing: Tk.S.s3) {
                SectionHeader("Fingerprint")
                FingerprintView(
                    parameters: FingerprintParameters(vector: FingerprintVector(summary: summary))
                )
                .frame(width: 220, height: 220)
            }

            VStack(alignment: .leading, spacing: Tk.S.s3) {
                SectionHeader("Speed by session", trailing: "most recent last")
                SpeedTrendChart(sessions: sessions.reversed())
            }
        }
    }

    private var recent: some View {
        VStack(alignment: .leading, spacing: Tk.S.s3) {
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
                        Rectangle().fill(Tk.C.strokeSoft).frame(height: 1)
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
        HStack(spacing: Tk.S.s4) {
            Text("Session \(index)")
                .font(Tk.F.body)
                .foregroundStyle(Tk.C.textPrimary)
                .frame(width: 96, alignment: .leading)

            Text(session.category.displayName)
                .font(Tk.F.body)
                .foregroundStyle(Tk.C.textSecondary)
                .frame(width: 96, alignment: .leading)

            RhythmBar(samples: session.metrics.rhythm, height: 26)
                .frame(maxWidth: .infinity)

            Text("\(Fmt.wpm(session.metrics.grossWPM)) wpm")
                .font(Tk.F.metricSm)
                .foregroundStyle(Tk.C.textPrimary)
                .frame(width: 88, alignment: .trailing)
        }
        .padding(.vertical, Tk.S.s3)
        .contentShape(Rectangle())
    }
}

/// Speed per session. Deliberately a real chart rather than a hand-drawn one —
/// it wants axes and a readable scale, which Charts already solves.
private struct SpeedTrendChart: View {
    let sessions: [SessionRecord]

    var body: some View {
        Chart(Array(sessions.enumerated()), id: \.element.id) { offset, session in
            LineMark(
                x: .value("Session", offset + 1),
                y: .value("Speed", session.metrics.grossWPM)
            )
            .foregroundStyle(Tk.C.textSecondary)
            .interpolationMethod(.monotone)

            PointMark(
                x: .value("Session", offset + 1),
                y: .value("Speed", session.metrics.grossWPM)
            )
            .foregroundStyle(Tk.C.textPrimary)
            .symbolSize(28)
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine().foregroundStyle(Tk.C.strokeSoft)
                AxisValueLabel {
                    if let wpm = value.as(Double.self) {
                        Text(Fmt.wpm(wpm))
                            .font(Tk.F.monoSm)
                            .foregroundStyle(Tk.C.textTertiary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(Tk.C.strokeSoft.opacity(0.5))
            }
        }
        .frame(height: 220)
    }
}

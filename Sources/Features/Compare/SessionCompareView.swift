import Charts
import SwiftUI
import TypingMirrorKit

/// How typing differs by what you were doing.
struct SessionCompareView: View {
    let sessions: [SessionRecord]

    private struct Row: Identifiable {
        let id: String
        let category: SessionCategory
        let sessionCount: Int
        let averageWPM: Double
        let correctionRate: Double
        let burstFraction: Double
        let pauseRate: Double
    }

    private var rows: [Row] {
        Dictionary(grouping: sessions, by: \.category)
            .map { category, group in
                func mean(_ value: (SessionMetrics) -> Double) -> Double {
                    group.reduce(0) { $0 + value($1.metrics) } / Double(group.count)
                }
                return Row(
                    id: category.rawValue,
                    category: category,
                    sessionCount: group.count,
                    averageWPM: mean { $0.grossWPM },
                    correctionRate: mean { $0.correctionRate },
                    burstFraction: mean { $0.burstFraction },
                    pauseRate: mean { $0.features.pauseRatePerMinute }
                )
            }
            .sorted { $0.averageWPM > $1.averageWPM }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.extraLarge) {
                header

                if rows.count < 2 {
                    EmptyHint(
                        title: "Not enough variety yet",
                        detail: "Once you have typed in more than one kind of app, "
                            + "this compares them."
                    )
                } else {
                    chart
                    table
                    reading
                }
            }
            .padding(.horizontal, Theme.Spacing.page)
            .padding(.vertical, Theme.Spacing.extraLarge)
            .frame(maxWidth: Theme.Layout.contentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
            Text("Compare")
                .font(Theme.Typography.pageTitle)
                .foregroundStyle(Theme.Colors.primaryText)
            Text("Your typing is not one habit. It changes with what you are writing.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.mutedText)
        }
    }

    private var chart: some View {
        Chart(rows) { row in
            BarMark(
                x: .value("Speed", row.averageWPM),
                y: .value("Kind", row.category.displayName)
            )
            .foregroundStyle(Theme.Colors.chartColor(0.55))
            .annotation(position: .trailing) {
                Text(DisplayFormat.wpm(row.averageWPM))
                    .font(Theme.Typography.smallMonospaced)
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
        }
        .chartXAxis {
            AxisMarks { _ in AxisGridLine().foregroundStyle(Theme.Colors.subtleBorder) }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let name = value.as(String.self) {
                        Text(name).font(Theme.Typography.body).foregroundStyle(Theme.Colors.secondaryText)
                    }
                }
            }
        }
        .frame(height: CGFloat(rows.count) * 46 + 40)
    }

    private var table: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Kind").frame(width: 120, alignment: .leading)
                Text("Sessions").frame(width: 80, alignment: .trailing)
                Text("Speed").frame(width: 80, alignment: .trailing)
                Text("Corrections").frame(width: 100, alignment: .trailing)
                Text("In bursts").frame(width: 90, alignment: .trailing)
                Spacer()
            }
            .font(Theme.Typography.label)
            .foregroundStyle(Theme.Colors.mutedText)
            .padding(.vertical, Theme.Spacing.small)

            Rectangle().fill(Theme.Colors.subtleBorder).frame(height: 1)

            ForEach(rows) { row in
                HStack {
                    Text(row.category.displayName)
                        .foregroundStyle(Theme.Colors.primaryText)
                        .frame(width: 120, alignment: .leading)
                    Text("\(row.sessionCount)").frame(width: 80, alignment: .trailing)
                    Text("\(DisplayFormat.wpm(row.averageWPM))").frame(width: 80, alignment: .trailing)
                    Text("\(DisplayFormat.percent(row.correctionRate))%").frame(width: 100, alignment: .trailing)
                    Text("\(DisplayFormat.percent(row.burstFraction))%").frame(width: 90, alignment: .trailing)
                    Spacer()
                }
                .font(Theme.Typography.smallMetric)
                .foregroundStyle(Theme.Colors.secondaryText)
                .padding(.vertical, Theme.Spacing.regular)

                Rectangle().fill(Theme.Colors.subtleBorder).frame(height: 1)
            }
        }
    }

    @ViewBuilder
    private var reading: some View {
        let summaries = rows
        if let fastest = summaries.first, let slowest = summaries.last,
           fastest.id != slowest.id {
            let gap = Int((fastest.averageWPM - slowest.averageWPM).rounded())
            let mostCorrections = summaries.max { $0.correctionRate < $1.correctionRate }

            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                SectionHeader("What this says")
                Text("You type \(gap) words a minute faster in "
                    + "\(fastest.category.displayName.lowercased()) than in "
                    + "\(slowest.category.displayName.lowercased()).")
                    .foregroundStyle(Theme.Colors.secondaryText)
                if let mostCorrections {
                    Text("You correct yourself most in "
                        + "\(mostCorrections.category.displayName.lowercased()), "
                        + "on \(DisplayFormat.percent(mostCorrections.correctionRate))% of keystrokes.")
                        .foregroundStyle(Theme.Colors.secondaryText)
                }
            }
            .font(Theme.Typography.body)
        }
    }
}

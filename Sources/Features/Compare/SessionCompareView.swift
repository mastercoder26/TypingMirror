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
            VStack(alignment: .leading, spacing: Tk.S.s6) {
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
            .padding(.horizontal, Tk.S.s7)
            .padding(.vertical, Tk.S.s6)
            .frame(maxWidth: Tk.L.contentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Tk.S.s1) {
            Text("Compare")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Tk.C.textPrimary)
            Text("Your typing is not one habit. It changes with what you are writing.")
                .font(Tk.F.body)
                .foregroundStyle(Tk.C.textTertiary)
        }
    }

    private var chart: some View {
        Chart(rows) { row in
            BarMark(
                x: .value("Speed", row.averageWPM),
                y: .value("Kind", row.category.displayName)
            )
            .foregroundStyle(Tk.C.viz(0.55))
            .annotation(position: .trailing) {
                Text(Fmt.wpm(row.averageWPM))
                    .font(Tk.F.monoSm)
                    .foregroundStyle(Tk.C.textSecondary)
            }
        }
        .chartXAxis {
            AxisMarks { _ in AxisGridLine().foregroundStyle(Tk.C.strokeSoft) }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let name = value.as(String.self) {
                        Text(name).font(Tk.F.body).foregroundStyle(Tk.C.textSecondary)
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
            .font(Tk.F.label)
            .foregroundStyle(Tk.C.textTertiary)
            .padding(.vertical, Tk.S.s2)

            Rectangle().fill(Tk.C.strokeSoft).frame(height: 1)

            ForEach(rows) { row in
                HStack {
                    Text(row.category.displayName)
                        .foregroundStyle(Tk.C.textPrimary)
                        .frame(width: 120, alignment: .leading)
                    Text("\(row.sessionCount)").frame(width: 80, alignment: .trailing)
                    Text("\(Fmt.wpm(row.averageWPM))").frame(width: 80, alignment: .trailing)
                    Text("\(Fmt.percent(row.correctionRate))%").frame(width: 100, alignment: .trailing)
                    Text("\(Fmt.percent(row.burstFraction))%").frame(width: 90, alignment: .trailing)
                    Spacer()
                }
                .font(Tk.F.metricSm)
                .foregroundStyle(Tk.C.textSecondary)
                .padding(.vertical, Tk.S.s3)

                Rectangle().fill(Tk.C.strokeSoft).frame(height: 1)
            }
        }
    }

    /// States the comparison in words, since the point of the screen is the
    /// contrast rather than the individual figures.
    private var reading: some View {
        let sorted = rows
        guard let fastest = sorted.first, let slowest = sorted.last, fastest.id != slowest.id
        else { return AnyView(EmptyView()) }

        let gap = Int((fastest.averageWPM - slowest.averageWPM).rounded())
        let messiest = sorted.max { $0.correctionRate < $1.correctionRate }

        return AnyView(
            VStack(alignment: .leading, spacing: Tk.S.s2) {
                SectionHeader("What this says")
                Text("You type \(gap) words a minute faster in "
                    + "\(fastest.category.displayName.lowercased()) than in "
                    + "\(slowest.category.displayName.lowercased()).")
                    .foregroundStyle(Tk.C.textSecondary)
                if let messiest {
                    Text("You correct yourself most in "
                        + "\(messiest.category.displayName.lowercased()), "
                        + "on \(Fmt.percent(messiest.correctionRate))% of keystrokes.")
                        .foregroundStyle(Tk.C.textSecondary)
                }
            }
            .font(Tk.F.body)
        )
    }
}

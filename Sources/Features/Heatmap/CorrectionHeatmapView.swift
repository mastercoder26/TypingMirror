import SwiftUI
import TypingMirrorKit

/// Corrections grouped by word position and progress through a session.
/// Word positions are stored without the characters themselves.
struct CorrectionHeatmapView: View {
    let sessions: [SessionRecord]
    @Environment(AppModel.self) private var model

    @State private var grid: [[Double]] = []
    @State private var isLoading = true

    private let positionBuckets = 12
    private let timeBuckets = 24

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.extraLarge) {
                header

                if isLoading {
                    Text("Reading sessions…")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.mutedText)
                } else if grid.isEmpty {
                    EmptyHint(
                        title: "No corrections recorded yet",
                        detail: "Type in the practice pad or run a speed test, and this fills in."
                    )
                } else {
                    chart
                    legend
                }
            }
            .padding(.horizontal, Theme.Spacing.page)
            .padding(.vertical, Theme.Spacing.extraLarge)
            .frame(maxWidth: Theme.Layout.contentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task(id: sessions.map(\.id)) { await load() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
            Text("Corrections")
                .font(Theme.Typography.pageTitle)
                .foregroundStyle(Theme.Colors.primaryText)
            Text("Where your backspaces land: how far into a word, and how far into the session.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.mutedText)
        }
    }

    private var chart: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            HStack(alignment: .top, spacing: Theme.Spacing.regular) {
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(0..<positionBuckets, id: \.self) { row in
                        Text(row == positionBuckets - 1 ? "\(row)+" : "\(row)")
                            .font(Theme.Typography.smallMonospaced)
                            .foregroundStyle(Theme.Colors.mutedText)
                            .frame(height: 22)
                    }
                }

                Canvas { context, size in
                    let cellWidth = size.width / CGFloat(timeBuckets)
                    let cellHeight = size.height / CGFloat(positionBuckets)
                    for row in 0..<positionBuckets {
                        for column in 0..<timeBuckets {
                            let value = grid[row][column]
                            let rect = CGRect(
                                x: CGFloat(column) * cellWidth + 1,
                                y: CGFloat(row) * cellHeight + 1,
                                width: cellWidth - 2,
                                height: cellHeight - 2
                            )
                            context.fill(
                                Path(roundedRect: rect, cornerRadius: 2),
                                with: .color(Theme.Colors.chartColor(value))
                            )
                        }
                    }
                }
                .frame(height: CGFloat(positionBuckets) * 22)
            }

            HStack {
                Text("start of session")
                Spacer()
                Text("end")
            }
            .font(Theme.Typography.caption)
            .foregroundStyle(Theme.Colors.mutedText)
            .padding(.leading, 34)
        }
    }

    private var legend: some View {
        HStack(spacing: Theme.Spacing.small) {
            Text("Characters into the word, vertically.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.mutedText)
            Spacer()
            Text("fewer")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.mutedText)
            HStack(spacing: 2) {
                ForEach(0..<6, id: \.self) { step in
                    Rectangle()
                        .fill(Theme.Colors.chartColor(Double(step) / 5))
                        .frame(width: 18, height: 10)
                }
            }
            Text("more")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.mutedText)
        }
    }

    private func load() async {
        isLoading = true
        var counts = Array(
            repeating: Array(repeating: 0.0, count: timeBuckets),
            count: positionBuckets
        )
        var sawAny = false

        for session in sessions.prefix(20) where session.hasReplay {
            let events = await model.events(for: session.id)
            guard events.count > 1 else { continue }
            for (index, event) in events.enumerated() where event.keyClass.isCorrection {
                sawAny = true
                let row = min(Int(event.wordPosition), positionBuckets - 1)
                let column = min(
                    Int(Double(index) / Double(events.count) * Double(timeBuckets)),
                    timeBuckets - 1
                )
                counts[row][column] += 1
            }
        }

        let peak = counts.flatMap { $0 }.max() ?? 0
        grid = sawAny && peak > 0
            ? counts.map { $0.map { $0 / peak } }
            : []
        isLoading = false
    }
}

struct EmptyHint: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text(title)
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.Colors.secondaryText)
            Text(detail)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.mutedText)
        }
        .padding(.vertical, Theme.Spacing.large)
    }
}

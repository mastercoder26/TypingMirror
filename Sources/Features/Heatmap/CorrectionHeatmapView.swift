import SwiftUI
import TypingMirrorKit

/// Where in a word corrections happen, across a session.
///
/// A plain Cartesian chart would not say anything useful here; the interesting
/// axis is position *inside the word*, which is the one thing stored that carries
/// no character identity.
struct CorrectionHeatmapView: View {
    let sessions: [SessionRecord]
    @Environment(AppModel.self) private var model

    @State private var grid: [[Double]] = []
    @State private var isLoading = true

    private let positionBuckets = 12
    private let timeBuckets = 24

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tk.S.s6) {
                header

                if isLoading {
                    Text("Reading sessions…")
                        .font(Tk.F.body)
                        .foregroundStyle(Tk.C.textTertiary)
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
            .padding(.horizontal, Tk.S.s7)
            .padding(.vertical, Tk.S.s6)
            .frame(maxWidth: Tk.L.contentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task(id: sessions.map(\.id)) { await load() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Tk.S.s1) {
            Text("Corrections")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Tk.C.textPrimary)
            Text("Where your backspaces land: how far into a word, and how far into the session.")
                .font(Tk.F.body)
                .foregroundStyle(Tk.C.textTertiary)
        }
    }

    private var chart: some View {
        VStack(alignment: .leading, spacing: Tk.S.s2) {
            HStack(alignment: .top, spacing: Tk.S.s3) {
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(0..<positionBuckets, id: \.self) { row in
                        Text(row == positionBuckets - 1 ? "\(row)+" : "\(row)")
                            .font(Tk.F.monoSm)
                            .foregroundStyle(Tk.C.textTertiary)
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
                                with: .color(Tk.C.viz(value))
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
            .font(Tk.F.caption)
            .foregroundStyle(Tk.C.textTertiary)
            .padding(.leading, 34)
        }
    }

    private var legend: some View {
        HStack(spacing: Tk.S.s2) {
            Text("Characters into the word, vertically.")
                .font(Tk.F.caption)
                .foregroundStyle(Tk.C.textTertiary)
            Spacer()
            Text("fewer")
                .font(Tk.F.caption)
                .foregroundStyle(Tk.C.textTertiary)
            HStack(spacing: 2) {
                ForEach(0..<6, id: \.self) { step in
                    Rectangle()
                        .fill(Tk.C.viz(Double(step) / 5))
                        .frame(width: 18, height: 10)
                }
            }
            Text("more")
                .font(Tk.F.caption)
                .foregroundStyle(Tk.C.textTertiary)
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
        VStack(alignment: .leading, spacing: Tk.S.s2) {
            Text(title)
                .font(Tk.F.title)
                .foregroundStyle(Tk.C.textSecondary)
            Text(detail)
                .font(Tk.F.body)
                .foregroundStyle(Tk.C.textTertiary)
        }
        .padding(.vertical, Tk.S.s5)
    }
}

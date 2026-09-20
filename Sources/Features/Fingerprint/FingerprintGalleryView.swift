import SwiftUI
import TypingMirrorKit

/// Every day's mark side by side, so style drift over time is visible at a glance.
struct FingerprintGalleryView: View {
    let days: [DailySummary]

    private let columns = [GridItem(.adaptive(minimum: 190), spacing: Tk.S.s5)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tk.S.s6) {
                VStack(alignment: .leading, spacing: Tk.S.s1) {
                    Text("Fingerprints")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(Tk.C.textPrimary)
                    Text("One mark per day, drawn from that day's rhythm. "
                        + "The same day always draws the same mark.")
                        .font(Tk.F.body)
                        .foregroundStyle(Tk.C.textTertiary)
                }

                LazyVGrid(columns: columns, alignment: .leading, spacing: Tk.S.s6) {
                    ForEach(days) { day in
                        VStack(alignment: .leading, spacing: Tk.S.s2) {
                            FingerprintView(
                                parameters: FingerprintParameters(
                                    vector: FingerprintVector(summary: day)
                                )
                            )
                            .frame(height: 190)

                            Text(Fmt.relativeDay(day.date))
                                .font(Tk.F.body)
                                .foregroundStyle(Tk.C.textPrimary)
                            Text("\(Fmt.wpm(day.averageWPM)) wpm · \(day.totalKeystrokes) keys")
                                .font(Tk.F.caption)
                                .foregroundStyle(Tk.C.textTertiary)
                        }
                    }
                }
            }
            .padding(.horizontal, Tk.S.s7)
            .padding(.vertical, Tk.S.s6)
            .frame(maxWidth: Tk.L.contentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
    }
}

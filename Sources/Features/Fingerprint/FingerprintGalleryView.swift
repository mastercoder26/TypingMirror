import SwiftUI
import TypingMirrorKit

/// Every day's mark side by side, so style drift over time is visible at a glance.
struct FingerprintGalleryView: View {
    let days: [DailySummary]

    private let columns = [GridItem(.adaptive(minimum: 190), spacing: Theme.Spacing.large)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.extraLarge) {
                VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
                    Text("Fingerprints")
                        .font(Theme.Typography.pageTitle)
                        .foregroundStyle(Theme.Colors.primaryText)
                    Text("One mark per day, drawn from that day's rhythm. "
                        + "The same day always draws the same mark.")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.mutedText)
                }

                LazyVGrid(columns: columns, alignment: .leading, spacing: Theme.Spacing.extraLarge) {
                    ForEach(days) { day in
                        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                            FingerprintView(
                                parameters: FingerprintParameters(
                                    vector: FingerprintVector(summary: day)
                                )
                            )
                            .frame(height: 190)

                            Text(DisplayFormat.relativeDay(day.date))
                                .font(Theme.Typography.body)
                                .foregroundStyle(Theme.Colors.primaryText)
                            Text("\(DisplayFormat.wpm(day.averageWPM)) wpm · \(day.totalKeystrokes) keys")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.mutedText)
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.page)
            .padding(.vertical, Theme.Spacing.extraLarge)
            .frame(maxWidth: Theme.Layout.contentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
    }
}

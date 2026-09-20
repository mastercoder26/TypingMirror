import SwiftUI
import TypingMirrorKit

/// Words you slow down on.
///
/// Only available under the lexical tier, and the screen says so plainly rather
/// than appearing broken when it is switched off.
struct HesitationListView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.extraLarge) {
                header

                if !model.settings.tier.storesText {
                    EmptyHint(
                        title: "Word hesitation is off",
                        detail: "This is the only feature that needs the words themselves. "
                            + "Turn on \u{201C}Rhythm and words\u{201D} in Settings to use it."
                    )
                } else if model.hesitations.isEmpty {
                    EmptyHint(
                        title: "Nothing recorded yet",
                        detail: "Run a speed test and the words you paused on will appear here."
                    )
                } else {
                    list
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
            Text("Hesitations")
                .font(Theme.Typography.pageTitle)
                .foregroundStyle(Theme.Colors.primaryText)
            Text("Words where you paused noticeably longer than your usual pace.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.mutedText)
        }
    }

    private var list: some View {
        let peak = model.hesitations.map(\.medianHesitationMs).max() ?? 1
        return VStack(spacing: 0) {
            ForEach(model.hesitations) { entry in
                HStack(spacing: Theme.Spacing.medium) {
                    Text(entry.word)
                        .font(Theme.Typography.monospaced)
                        .foregroundStyle(Theme.Colors.primaryText)
                        .frame(width: 160, alignment: .leading)

                    GeometryReader { geometry in
                        Capsule()
                            .fill(Theme.Colors.chartColor(0.5))
                            .frame(
                                width: geometry.size.width * (entry.medianHesitationMs / peak),
                                height: 8
                            )
                            .frame(maxHeight: .infinity, alignment: .center)
                    }
                    .frame(height: 20)

                    Text("\(DisplayFormat.seconds(ms: entry.medianHesitationMs))s")
                        .font(Theme.Typography.smallMetric)
                        .foregroundStyle(Theme.Colors.secondaryText)
                        .frame(width: 70, alignment: .trailing)

                    Text("\(entry.occurrences)×")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.mutedText)
                        .frame(width: 44, alignment: .trailing)
                }
                .padding(.vertical, Theme.Spacing.regular)

                Rectangle().fill(Theme.Colors.subtleBorder).frame(height: 1)
            }
        }
    }
}

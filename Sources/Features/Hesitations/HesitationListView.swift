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
            VStack(alignment: .leading, spacing: Tk.S.s6) {
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
            .padding(.horizontal, Tk.S.s7)
            .padding(.vertical, Tk.S.s6)
            .frame(maxWidth: Tk.L.contentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Tk.S.s1) {
            Text("Hesitations")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Tk.C.textPrimary)
            Text("Words where you paused noticeably longer than your usual pace.")
                .font(Tk.F.body)
                .foregroundStyle(Tk.C.textTertiary)
        }
    }

    private var list: some View {
        let peak = model.hesitations.map(\.medianHesitationMs).max() ?? 1
        return VStack(spacing: 0) {
            ForEach(model.hesitations) { entry in
                HStack(spacing: Tk.S.s4) {
                    Text(entry.word)
                        .font(Tk.F.mono)
                        .foregroundStyle(Tk.C.textPrimary)
                        .frame(width: 160, alignment: .leading)

                    GeometryReader { geometry in
                        Capsule()
                            .fill(Tk.C.viz(0.5))
                            .frame(
                                width: geometry.size.width * (entry.medianHesitationMs / peak),
                                height: 8
                            )
                            .frame(maxHeight: .infinity, alignment: .center)
                    }
                    .frame(height: 20)

                    Text("\(Fmt.seconds(ms: entry.medianHesitationMs))s")
                        .font(Tk.F.metricSm)
                        .foregroundStyle(Tk.C.textSecondary)
                        .frame(width: 70, alignment: .trailing)

                    Text("\(entry.occurrences)×")
                        .font(Tk.F.caption)
                        .foregroundStyle(Tk.C.textTertiary)
                        .frame(width: 44, alignment: .trailing)
                }
                .padding(.vertical, Tk.S.s3)

                Rectangle().fill(Tk.C.strokeSoft).frame(height: 1)
            }
        }
    }
}

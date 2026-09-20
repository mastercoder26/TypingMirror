import SwiftUI
import TypingMirrorKit

/// Recent sessions, with the selected one shown in full.
struct SessionListView: View {
    let sessions: [SessionRecord]
    @Binding var selection: SessionRecord.ID?
    var onReplay: (SessionRecord) -> Void
    var onDelete: (UUID) -> Void

    private var selected: SessionRecord? {
        sessions.first { $0.id == selection } ?? sessions.first
    }

    private var selectedIndex: Int {
        guard let selected,
              let position = sessions.firstIndex(where: { $0.id == selected.id })
        else { return 0 }
        return sessions.count - position
    }

    var body: some View {
        if sessions.isEmpty {
            EmptyHint(
                title: "No sessions yet",
                detail: "Run a speed test, use the practice pad, or turn on watching "
                    + "other apps in Settings."
            )
            .padding(Tk.S.s7)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            HSplitView {
                list.frame(minWidth: 260, idealWidth: 290, maxWidth: 360)
                if let selected {
                    SessionDetailView(
                        session: selected,
                        index: selectedIndex,
                        onReplay: { onReplay(selected) },
                        onDelete: { onDelete(selected.id) }
                    )
                }
            }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(sessions.enumerated()), id: \.element.id) { offset, session in
                    SessionRow(
                        session: session,
                        index: sessions.count - offset,
                        isSelected: session.id == selected?.id
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { selection = session.id }

                    if offset < sessions.count - 1 {
                        Rectangle()
                            .fill(Tk.C.strokeSoft)
                            .frame(height: 1)
                            .padding(.leading, Tk.S.s4)
                    }
                }
            }
            .padding(.vertical, Tk.S.s3)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
    }
}

private struct SessionRow: View {
    let session: SessionRecord
    let index: Int
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: Tk.S.s3) {
            VStack(alignment: .leading, spacing: Tk.S.s1) {
                Text("Session \(index)")
                    .font(Tk.F.title)
                    .foregroundStyle(Tk.C.textPrimary)
                Text("\(session.category.displayName) · \(Fmt.relativeDay(session.startedAt))")
                    .font(Tk.F.caption)
                    .foregroundStyle(Tk.C.textTertiary)
            }

            Spacer(minLength: Tk.S.s2)

            Text(Fmt.wpm(session.metrics.grossWPM))
                .font(Tk.F.metricSm)
                .foregroundStyle(isSelected ? Tk.C.textPrimary : Tk.C.textSecondary)
        }
        .padding(.horizontal, Tk.S.s4)
        .padding(.vertical, Tk.S.s3)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: Tk.R.sm, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .padding(.horizontal, Tk.S.s2)
            }
        }
    }
}

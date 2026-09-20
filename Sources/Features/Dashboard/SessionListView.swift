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
            .padding(Theme.Spacing.page)
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
                            .fill(Theme.Colors.subtleBorder)
                            .frame(height: 1)
                            .padding(.leading, Theme.Spacing.medium)
                    }
                }
            }
            .padding(.vertical, Theme.Spacing.regular)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
    }
}

private struct SessionRow: View {
    let session: SessionRecord
    let index: Int
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.regular) {
            VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
                Text("Session \(index)")
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.Colors.primaryText)
                Text("\(session.category.displayName) · \(DisplayFormat.relativeDay(session.startedAt))")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.mutedText)
            }

            Spacer(minLength: Theme.Spacing.small)

            Text(DisplayFormat.wpm(session.metrics.grossWPM))
                .font(Theme.Typography.smallMetric)
                .foregroundStyle(isSelected ? Theme.Colors.primaryText : Theme.Colors.secondaryText)
        }
        .padding(.horizontal, Theme.Spacing.medium)
        .padding(.vertical, Theme.Spacing.regular)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .padding(.horizontal, Theme.Spacing.small)
            }
        }
    }
}

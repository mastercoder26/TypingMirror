import SwiftUI

/// Raycast-style command surface.
///
/// Focus stays in the field permanently and the arrow keys are intercepted there,
/// rather than using a `List` with a selection binding — AppKit would move focus
/// into the table and the caret would disappear mid-typing.
struct CommandPaletteView: View {
    @Bindable var model: PaletteModel
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            field
            if !model.results.isEmpty {
                Divider().overlay(Theme.Colors.subtleBorder)
                results
            } else {
                empty
            }
        }
        .frame(width: 560)
        .background(Theme.Colors.background.opacity(0.86))
        .glassEffect(.clear, in: RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)
                .strokeBorder(Theme.Colors.strongBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(Theme.Shadows.floatOpacity), radius: Theme.Shadows.floatRadius, y: Theme.Shadows.floatY)
        .onAppear { isFieldFocused = true }
    }

    private var field: some View {
        HStack(spacing: Theme.Spacing.regular) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.Colors.mutedText)

            TextField("Search sessions and actions", text: $model.query)
                .textFieldStyle(.plain)
                .font(.system(size: 18))
                .foregroundStyle(Theme.Colors.primaryText)
                .focused($isFieldFocused)
                .onSubmit { model.runSelected() }
                .onKeyPress(.upArrow) { model.moveSelection(by: -1); return .handled }
                .onKeyPress(.downArrow) { model.moveSelection(by: 1); return .handled }
                .onKeyPress(.escape) { model.dismiss(); return .handled }
        }
        .padding(.horizontal, Theme.Spacing.medium)
        .padding(.vertical, Theme.Spacing.medium)
    }

    private var results: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(model.results.enumerated()), id: \.element.id) { index, command in
                        PaletteRow(command: command, isSelected: index == model.selectedIndex)
                            .id(command.id)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                model.selectedIndex = index
                                model.runSelected()
                            }
                    }
                }
                .padding(Theme.Spacing.small)
            }
            .frame(maxHeight: 340)
            .onChange(of: model.selectedIndex) { _, _ in
                guard let id = model.selected?.id else { return }
                withAnimation(.easeOut(duration: 0.12)) {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
        }
    }

    private var empty: some View {
        Text("No matches")
            .font(Theme.Typography.body)
            .foregroundStyle(Theme.Colors.mutedText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.Spacing.medium)
            .padding(.bottom, Theme.Spacing.medium)
    }
}

private struct PaletteRow: View {
    let command: PaletteCommand
    let isSelected: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.regular) {
            Image(systemName: command.symbol)
                .font(.system(size: 13))
                .foregroundStyle(isSelected ? Theme.Colors.primaryText : Theme.Colors.mutedText)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(command.title)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.primaryText)
                if let subtitle = command.subtitle {
                    Text(subtitle)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.mutedText)
                }
            }

            Spacer(minLength: Theme.Spacing.regular)

            Text(command.section)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.mutedText)
        }
        .padding(.horizontal, Theme.Spacing.regular)
        .padding(.vertical, Theme.Spacing.small)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: Theme.Radius.extraSmall, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            }
        }
    }
}

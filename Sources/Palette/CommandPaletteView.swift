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
                Divider().overlay(Tk.C.strokeSoft)
                results
            } else {
                empty
            }
        }
        .frame(width: 560)
        .background(Tk.C.bgBase.opacity(0.86))
        .glassEffect(.clear, in: RoundedRectangle(cornerRadius: Tk.R.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Tk.R.lg, style: .continuous)
                .strokeBorder(Tk.C.strokeHard, lineWidth: 1)
        )
        .shadow(color: .black.opacity(Tk.Z.floatOpacity), radius: Tk.Z.floatRadius, y: Tk.Z.floatY)
        .onAppear { isFieldFocused = true }
    }

    private var field: some View {
        HStack(spacing: Tk.S.s3) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Tk.C.textTertiary)

            TextField("Search sessions and actions", text: $model.query)
                .textFieldStyle(.plain)
                .font(.system(size: 18))
                .foregroundStyle(Tk.C.textPrimary)
                .focused($isFieldFocused)
                .onSubmit { model.runSelected() }
                .onKeyPress(.upArrow) { model.moveSelection(by: -1); return .handled }
                .onKeyPress(.downArrow) { model.moveSelection(by: 1); return .handled }
                .onKeyPress(.escape) { model.dismiss(); return .handled }
        }
        .padding(.horizontal, Tk.S.s4)
        .padding(.vertical, Tk.S.s4)
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
                .padding(Tk.S.s2)
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
            .font(Tk.F.body)
            .foregroundStyle(Tk.C.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Tk.S.s4)
            .padding(.bottom, Tk.S.s4)
    }
}

private struct PaletteRow: View {
    let command: PaletteCommand
    let isSelected: Bool

    var body: some View {
        HStack(spacing: Tk.S.s3) {
            Image(systemName: command.symbol)
                .font(.system(size: 13))
                .foregroundStyle(isSelected ? Tk.C.textPrimary : Tk.C.textTertiary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(command.title)
                    .font(Tk.F.body)
                    .foregroundStyle(Tk.C.textPrimary)
                if let subtitle = command.subtitle {
                    Text(subtitle)
                        .font(Tk.F.caption)
                        .foregroundStyle(Tk.C.textTertiary)
                }
            }

            Spacer(minLength: Tk.S.s3)

            Text(command.section)
                .font(Tk.F.caption)
                .foregroundStyle(Tk.C.textTertiary)
        }
        .padding(.horizontal, Tk.S.s3)
        .padding(.vertical, Tk.S.s2)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: Tk.R.xs, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            }
        }
    }
}

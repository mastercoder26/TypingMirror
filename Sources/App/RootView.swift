import SwiftUI
import TypingMirrorKit

struct RootView: View {
    @Environment(AppModel.self) private var model

    @State private var selection: SidebarItem = .today
    @AppStorage("onboarding.completed.v1") private var hasOnboarded = false
    @State private var showingOnboarding = false

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            ZStack {
                AppBackdrop()
                detail
            }
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView(isPresented: $showingOnboarding)
                .onDisappear { hasOnboarded = true }
        }
        .task {
            await model.start()
            if !hasOnboarded { showingOnboarding = true }
        }
    }

    private var sidebar: some View {
        List(selection: $selection) {
            ForEach(SidebarItem.sections, id: \.self) { section in
                let items = SidebarItem.allCases.filter { $0.section == section }
                if !items.isEmpty {
                    Section(section) {
                        ForEach(items) { item in
                            Label(item.title, systemImage: item.symbol).tag(item)
                        }
                    }
                }
            }
        }
        .navigationSplitViewColumnWidth(Tk.L.sidebarWidth)
    }

    @ViewBuilder
    private var detail: some View {
        switch selection {
        case .today:
            VStack(alignment: .leading, spacing: Tk.S.s4) {
                Text("Today")
                    .font(Tk.F.title)
                    .foregroundStyle(Tk.C.textPrimary)
                Text("Sessions will land here once capture is wired up.")
                    .font(Tk.F.body)
                    .foregroundStyle(Tk.C.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(Tk.S.s6)
        case .settings:
            SettingsView()
        }
    }
}

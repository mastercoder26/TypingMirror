import SwiftUI
import TypingMirrorKit

struct RootView: View {
    @Environment(AppModel.self) private var model
    @State private var selection: SidebarItem = .today
    @State private var selectedSession: SessionRecord.ID?
    @State private var replaySession: SessionRecord?
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
        .sheet(item: $replaySession) { session in
            ReplayView(session: session)
                .frame(minWidth: 860, minHeight: 520)
                .background(Theme.Colors.background)
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
        .navigationSplitViewColumnWidth(Theme.Layout.sidebarWidth)
        .safeAreaInset(edge: .bottom) { sidebarFooter }
    }

    private var sidebarFooter: some View {
        HStack(spacing: Theme.Spacing.small) {
            if let coordinator = model.coordinator, coordinator.state == .running {
                Circle().fill(Theme.Colors.primaryText).frame(width: 5, height: 5)
                Text("Watching").font(Theme.Typography.caption).foregroundStyle(Theme.Colors.secondaryText)
            }
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.medium)
        .padding(.vertical, Theme.Spacing.regular)
    }

    @ViewBuilder
    private var detail: some View {
        switch selection {
        case .today:
            DashboardView(sessions: model.sessions, days: model.days) { id in
                selectedSession = id
                selection = .sessions
            }
        case .sessions:
            SessionListView(
                sessions: model.sessions,
                selection: $selectedSession,
                onReplay: { replaySession = $0 },
                onDelete: { id in Task { await model.delete(sessionID: id) } }
            )
        case .compare:
            SessionCompareView(sessions: model.sessions)
        case .corrections:
            CorrectionHeatmapView(sessions: model.sessions)
        case .fingerprint:
            FingerprintGalleryView(days: model.days)
        case .speedTest:
            SpeedTestView()
        case .practice:
            PracticePadView()
        case .settings:
            SettingsView()
        }
    }
}

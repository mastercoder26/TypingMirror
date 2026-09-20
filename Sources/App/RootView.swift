import SwiftUI
import TypingMirrorKit

struct RootView: View {
    @Environment(AppModel.self) private var model

    @State private var selection: SidebarItem = .today
    @State private var selectedSession: SessionRecord.ID?
    @State private var replaySession: SessionRecord?
    @State private var palette = PaletteModel()
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
        .overlay { if palette.isPresented { paletteOverlay } }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView(isPresented: $showingOnboarding)
                .onDisappear { hasOnboarded = true }
        }
        .sheet(item: $replaySession) { session in
            ReplayView(session: session)
                .frame(minWidth: 860, minHeight: 520)
                .background(Tk.C.bgBase)
        }
        .task {
            await model.start()
            rebuildCommands()
            if !hasOnboarded { showingOnboarding = true }
        }
        .onChange(of: model.sessions.map(\.id)) { _, _ in rebuildCommands() }
        .background {
            Button("") { palette.present() }
                .keyboardShortcut("k", modifiers: .command)
                .hidden()
        }
    }

    // MARK: Sidebar

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
        .safeAreaInset(edge: .bottom) { sidebarFooter }
    }

    private var sidebarFooter: some View {
        VStack(alignment: .leading, spacing: Tk.S.s2) {
            if let coordinator = model.coordinator, coordinator.state == .running {
                HStack(spacing: Tk.S.s2) {
                    Circle()
                        .fill(Tk.C.textPrimary)
                        .frame(width: 5, height: 5)
                    Text("Watching")
                        .font(Tk.F.caption)
                        .foregroundStyle(Tk.C.textSecondary)
                }
            }
            HStack {
                Text("Search").font(Tk.F.caption).foregroundStyle(Tk.C.textTertiary)
                Spacer()
                Text("⌘K").font(Tk.F.monoSm).foregroundStyle(Tk.C.textTertiary)
            }
        }
        .padding(.horizontal, Tk.S.s4)
        .padding(.vertical, Tk.S.s3)
    }

    // MARK: Detail

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
        case .hesitations:
            HesitationListView()
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

    private var paletteOverlay: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.28)
                .ignoresSafeArea()
                .onTapGesture { palette.dismiss() }
            CommandPaletteView(model: palette)
                .padding(.top, 110)
                .transition(.scale(scale: 0.97).combined(with: .opacity))
        }
    }

    private func rebuildCommands() {
        var commands: [PaletteCommand] = SidebarItem.allCases.map { item in
            PaletteCommand(
                id: "nav.\(item.id)",
                title: item.title,
                symbol: item.symbol,
                section: "Go to",
                keywords: ["open", "show", item.section]
            ) { selection = item }
        }

        for (offset, session) in model.sessions.enumerated() {
            let index = model.sessions.count - offset
            commands.append(
                PaletteCommand(
                    id: "session.\(session.id)",
                    title: "Session \(index)",
                    subtitle: "\(session.category.displayName) · "
                        + "\(Fmt.wpm(session.metrics.grossWPM)) wpm · "
                        + Fmt.relativeDay(session.startedAt),
                    symbol: "waveform",
                    section: "Sessions",
                    keywords: [session.category.displayName, session.appName ?? ""]
                ) {
                    selectedSession = session.id
                    selection = .sessions
                }
            )
        }

        palette.commands = commands
    }
}

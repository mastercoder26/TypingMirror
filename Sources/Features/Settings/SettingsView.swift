import SwiftUI
import TypingMirrorKit

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var showingWordInspector = false
    @State private var confirmLexical = ""
    @State private var showingLexicalConfirm = false

    var body: some View {
        @Bindable var model = model

        ScrollView {
            VStack(alignment: .leading, spacing: Tk.S.s7) {
                header
                captureSection
                privacySection
                if model.settings.tier.storesText { lexicalSection }
                dataSection
            }
            .padding(.horizontal, Tk.S.s7)
            .padding(.vertical, Tk.S.s6)
            .frame(maxWidth: 780, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .sheet(isPresented: $showingWordInspector) {
            StoredWordsInspector()
                .environment(model)
        }
        .alert("Store the words you type?", isPresented: $showingLexicalConfirm) {
            TextField("Type ALLOW to confirm", text: $confirmLexical)
            Button("Cancel", role: .cancel) { confirmLexical = "" }
            Button("Enable") {
                if confirmLexical.uppercased() == "ALLOW" {
                    model.settings.tier = .lexical
                }
                confirmLexical = ""
            }
        } message: {
            Text("This is the only setting that keeps anything you typed. "
                + "Words are filtered for anything credential-shaped, kept on this Mac only, "
                + "and deleted after \(model.settings.wordRetentionDays) days. "
                + "You can see and delete everything stored at any time.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Tk.S.s1) {
            Text("Settings")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Tk.C.textPrimary)
            Text("TypingMirror only watches while it is open. There is no background agent.")
                .font(Tk.F.body)
                .foregroundStyle(Tk.C.textTertiary)
        }
    }

    private var captureSection: some View {
        @Bindable var model = model

        return VStack(alignment: .leading, spacing: Tk.S.s3) {
            SectionHeader("Capture")

            Toggle(isOn: $model.settings.isGlobalCaptureEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Watch typing in other apps")
                        .foregroundStyle(Tk.C.textPrimary)
                    Text("Needs Input Monitoring permission. Without it, "
                        + "the speed test and practice pad still work.")
                        .font(Tk.F.caption)
                        .foregroundStyle(Tk.C.textTertiary)
                }
            }
            .toggleStyle(.switch)
            .font(Tk.F.body)

            if let coordinator = model.coordinator {
                captureStatus(coordinator)
            }
        }
    }

    @ViewBuilder
    private func captureStatus(_ coordinator: CaptureCoordinator) -> some View {
        switch coordinator.state {
        case .running:
            statusLine(
                "Watching. \(coordinator.liveKeystrokeCount) keystrokes seen this run.",
                detail: coordinator.isSecureInputActive
                    ? "Paused right now because a password field has focus."
                    : nil
            )
        case .needsPermission:
            VStack(alignment: .leading, spacing: Tk.S.s2) {
                statusLine(
                    CapturePermissions.missingDescription
                        ?? "Waiting for permission to take effect.",
                    detail: "Turn TypingMirror on under Input Monitoring. "
                        + "Capture starts on its own within a couple of seconds — "
                        + "no need to restart the app."
                )
                HStack(spacing: Tk.S.s2) {
                    Button("Request permission") { coordinator.requestPermission() }
                        .buttonStyle(.glassProminent)
                        .tint(Tk.C.accent)
                        .foregroundStyle(Tk.C.bgBase)
                        .accessibilityLabel("Request permission")
                    Button("Open Input Monitoring") {
                        CapturePermissions.openSettings(.inputMonitoring)
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel("Open Input Monitoring")
                    Button("Open Accessibility") {
                        CapturePermissions.openSettings(.accessibility)
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel("Open Accessibility")
                }
                permissionDetail
            }
        case .stopped:
            statusLine("Not watching other apps.", detail: nil)
        }
    }

    /// Shows both switches and their live state, so it is obvious which one is
    /// missing rather than leaving the user guessing between two similar panes.
    private var permissionDetail: some View {
        VStack(alignment: .leading, spacing: 2) {
            permissionRow("Input Monitoring", CapturePermissions.inputMonitoring, required: true)
            permissionRow("Accessibility", CapturePermissions.accessibility, required: false)
        }
        .padding(.top, Tk.S.s1)
    }

    private func permissionRow(
        _ name: String,
        _ status: CapturePermissions.Status,
        required: Bool
    ) -> some View {
        HStack(spacing: Tk.S.s2) {
            Image(systemName: status == .granted ? "checkmark" : "xmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(status == .granted ? Tk.C.textPrimary : Tk.C.textTertiary)
                .frame(width: 12)
            Text(name)
                .font(Tk.F.caption)
                .foregroundStyle(Tk.C.textSecondary)
            Text(required ? "required for keystroke timing" : "helps on some macOS versions")
                .font(Tk.F.caption)
                .foregroundStyle(Tk.C.textTertiary)
        }
    }

    private func statusLine(_ text: String, detail: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(text).font(Tk.F.body).foregroundStyle(Tk.C.textSecondary)
            if let detail {
                Text(detail).font(Tk.F.caption).foregroundStyle(Tk.C.textTertiary)
            }
        }
    }

    private var privacySection: some View {
        @Bindable var model = model

        return VStack(alignment: .leading, spacing: Tk.S.s3) {
            SectionHeader("What is stored")

            ForEach(PrivacyTier.allCases) { tier in
                Button {
                    if tier == .lexical {
                        showingLexicalConfirm = true
                    } else {
                        model.settings.tier = tier
                    }
                } label: {
                    HStack(alignment: .top, spacing: Tk.S.s3) {
                        Image(systemName: model.settings.tier == tier
                            ? "largecircle.fill.circle" : "circle")
                            .foregroundStyle(model.settings.tier == tier
                                ? Tk.C.textPrimary : Tk.C.textTertiary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tier.title)
                                .font(Tk.F.body)
                                .foregroundStyle(Tk.C.textPrimary)
                            Text(tier.summary)
                                .font(Tk.F.caption)
                                .foregroundStyle(Tk.C.textTertiary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                    }
                    .padding(.vertical, Tk.S.s2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Text("Password fields are never visible to TypingMirror — macOS does not "
                + "deliver those keystrokes to any app. Password managers and Mail "
                + "are excluded as well.")
                .font(Tk.F.caption)
                .foregroundStyle(Tk.C.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var lexicalSection: some View {
        VStack(alignment: .leading, spacing: Tk.S.s3) {
            SectionHeader("Stored words", trailing: "\(model.storedWordCount) kept")
            Text("Deleted automatically after \(model.settings.wordRetentionDays) days.")
                .font(Tk.F.body)
                .foregroundStyle(Tk.C.textSecondary)
            HStack(spacing: Tk.S.s2) {
                Button("See everything stored") { showingWordInspector = true }
                    .buttonStyle(.glass)
                    .accessibilityLabel("See everything stored")
                Button("Delete all words", role: .destructive) {
                    Task { await model.purgeStoredWords() }
                }
                .buttonStyle(.glass)
                .accessibilityLabel("Delete all words")
            }
        }
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: Tk.S.s3) {
            SectionHeader("Data")
            Text("\(model.sessions.count) sessions stored on this Mac. Nothing is ever uploaded.")
                .font(Tk.F.body)
                .foregroundStyle(Tk.C.textSecondary)
            Button("Delete all sessions", role: .destructive) {
                Task { await model.deleteAllSessions() }
            }
            .buttonStyle(.glass)
            .accessibilityLabel("Delete all sessions")
        }
    }
}

/// Shows exactly which words are held, because a list you can inspect is the only
/// thing that makes storing them defensible.
private struct StoredWordsInspector: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var words: [StoredWordEntry] = []

    var body: some View {
        VStack(alignment: .leading, spacing: Tk.S.s4) {
            Text("Everything TypingMirror has stored")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Tk.C.textPrimary)

            if words.isEmpty {
                Text("Nothing stored.").font(Tk.F.body).foregroundStyle(Tk.C.textTertiary)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(words) { word in
                            HStack {
                                Text(word.text).font(Tk.F.mono).foregroundStyle(Tk.C.textPrimary)
                                Spacer()
                                Text(word.isFromTest ? "typing test" : "global")
                                    .font(Tk.F.caption)
                                    .foregroundStyle(Tk.C.textTertiary)
                            }
                            .padding(.vertical, Tk.S.s2)
                            Rectangle().fill(Tk.C.strokeSoft).frame(height: 1)
                        }
                    }
                }
                .frame(maxHeight: 360)
            }

            HStack {
                Button("Delete everything", role: .destructive) {
                    Task {
                        await model.purgeStoredWords()
                        words = []
                    }
                }
                .buttonStyle(.glass)
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.glassProminent)
                    .tint(Tk.C.accent)
                    .foregroundStyle(Tk.C.bgBase)
            }
        }
        .padding(Tk.S.s6)
        .frame(width: 520)
        .background(Tk.C.bgBase)
        .task { words = await model.storedWords() }
    }
}

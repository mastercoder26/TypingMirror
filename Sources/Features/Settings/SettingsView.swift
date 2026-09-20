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
            VStack(alignment: .leading, spacing: Theme.Spacing.page) {
                header
                captureSection
                privacySection
                if model.settings.tier.storesText { lexicalSection }
                dataSection
            }
            .padding(.horizontal, Theme.Spacing.page)
            .padding(.vertical, Theme.Spacing.extraLarge)
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
        VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
            Text("Settings")
                .font(Theme.Typography.pageTitle)
                .foregroundStyle(Theme.Colors.primaryText)
            Text("TypingMirror only watches while it is open. There is no background agent.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.mutedText)
        }
    }

    private var captureSection: some View {
        @Bindable var model = model

        return VStack(alignment: .leading, spacing: Theme.Spacing.regular) {
            SectionHeader("Capture")

            Toggle(isOn: $model.settings.isGlobalCaptureEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Watch typing in other apps")
                        .foregroundStyle(Theme.Colors.primaryText)
                    Text("Needs Input Monitoring permission. Without it, "
                        + "the speed test and practice pad still work.")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.mutedText)
                }
            }
            .toggleStyle(.switch)
            .font(Theme.Typography.body)

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
            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                statusLine(
                    CapturePermissions.missingDescription
                        ?? "Waiting for permission to take effect.",
                    detail: "Turn TypingMirror on under Input Monitoring. "
                        + "Capture starts on its own within a couple of seconds — "
                        + "no need to restart the app."
                )
                HStack(spacing: Theme.Spacing.small) {
                    Button("Request permission") { coordinator.requestPermission() }
                        .buttonStyle(.glassProminent)
                        .tint(Theme.Colors.accent)
                        .foregroundStyle(Theme.Colors.background)
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
        .padding(.top, Theme.Spacing.tight)
    }

    private func permissionRow(
        _ name: String,
        _ status: CapturePermissions.Status,
        required: Bool
    ) -> some View {
        HStack(spacing: Theme.Spacing.small) {
            Image(systemName: status == .granted ? "checkmark" : "xmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(status == .granted ? Theme.Colors.primaryText : Theme.Colors.mutedText)
                .frame(width: 12)
            Text(name)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.secondaryText)
            Text(required ? "required for keystroke timing" : "helps on some macOS versions")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.mutedText)
        }
    }

    private func statusLine(_ text: String, detail: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(text).font(Theme.Typography.body).foregroundStyle(Theme.Colors.secondaryText)
            if let detail {
                Text(detail).font(Theme.Typography.caption).foregroundStyle(Theme.Colors.mutedText)
            }
        }
    }

    private var privacySection: some View {
        @Bindable var model = model

        return VStack(alignment: .leading, spacing: Theme.Spacing.regular) {
            SectionHeader("What is stored")

            ForEach(PrivacyTier.allCases) { tier in
                Button {
                    if tier == .lexical {
                        showingLexicalConfirm = true
                    } else {
                        model.settings.tier = tier
                    }
                } label: {
                    HStack(alignment: .top, spacing: Theme.Spacing.regular) {
                        Image(systemName: model.settings.tier == tier
                            ? "largecircle.fill.circle" : "circle")
                            .foregroundStyle(model.settings.tier == tier
                                ? Theme.Colors.primaryText : Theme.Colors.mutedText)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tier.title)
                                .font(Theme.Typography.body)
                                .foregroundStyle(Theme.Colors.primaryText)
                            Text(tier.summary)
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.mutedText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                    }
                    .padding(.vertical, Theme.Spacing.small)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Text("Password fields are never visible to TypingMirror — macOS does not "
                + "deliver those keystrokes to any app. Password managers and Mail "
                + "are excluded as well.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.mutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var lexicalSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.regular) {
            SectionHeader("Stored words", trailing: "\(model.storedWordCount) kept")
            Text("Deleted automatically after \(model.settings.wordRetentionDays) days.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.secondaryText)
            HStack(spacing: Theme.Spacing.small) {
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
        VStack(alignment: .leading, spacing: Theme.Spacing.regular) {
            SectionHeader("Data")
            Text("\(model.sessions.count) sessions stored on this Mac. Nothing is ever uploaded.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.secondaryText)
            Button("Delete all sessions", role: .destructive) {
                Task { await model.deleteAllSessions() }
            }
            .buttonStyle(.glass)
            .accessibilityLabel("Delete all sessions")
        }
    }
}

/// Lists retained words and lets the user clear them.
private struct StoredWordsInspector: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var words: [StoredWordEntry] = []

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("Everything TypingMirror has stored")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.Colors.primaryText)

            if words.isEmpty {
                Text("Nothing stored.").font(Theme.Typography.body).foregroundStyle(Theme.Colors.mutedText)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(words) { word in
                            HStack {
                                Text(word.text).font(Theme.Typography.monospaced).foregroundStyle(Theme.Colors.primaryText)
                                Spacer()
                                Text(word.isFromTest ? "typing test" : "global")
                                    .font(Theme.Typography.caption)
                                    .foregroundStyle(Theme.Colors.mutedText)
                            }
                            .padding(.vertical, Theme.Spacing.small)
                            Rectangle().fill(Theme.Colors.subtleBorder).frame(height: 1)
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
                    .tint(Theme.Colors.accent)
                    .foregroundStyle(Theme.Colors.background)
            }
        }
        .padding(Theme.Spacing.extraLarge)
        .frame(width: 520)
        .background(Theme.Colors.background)
        .task { words = await model.storedWords() }
    }
}

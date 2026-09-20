import SwiftUI
import TypingMirrorKit

/// First run. Explains what is measured before asking for anything.
struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.extraLarge) {
            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                Text("TypingMirror")
                    .font(Theme.Typography.pageTitle)
                    .foregroundStyle(Theme.Colors.primaryText)
                Text("It measures how you type, not what you type.")
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.Colors.secondaryText)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                point(
                    "Timing, not text",
                    "Every keystroke becomes two things: when it happened, and what kind of key "
                        + "it was. The key itself is resolved and thrown away before anything is "
                        + "recorded."
                )
                point(
                    "Nothing leaves this Mac",
                    "There is no account, no sync and no network call. Everything is a local file."
                )
                point(
                    "Passwords are invisible",
                    "macOS does not deliver keystrokes to any app while a password field has "
                        + "focus, so they cannot reach TypingMirror even by accident."
                )
            }

            Divider().overlay(Theme.Colors.subtleBorder)

            VStack(alignment: .leading, spacing: Theme.Spacing.regular) {
                Text("Watch typing in other apps?")
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.Colors.primaryText)
                Text("This is what makes it possible to compare coding against writing against "
                    + "messaging. It needs Input Monitoring permission, and you can turn it "
                    + "off at any time.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.mutedText)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: Theme.Spacing.regular) {
                    Button("Turn on and grant access") {
                        model.settings.isGlobalCaptureEnabled = true
                        model.coordinator?.requestPermission()
                        isPresented = false
                    }
                    .buttonStyle(.glassProminent)
                    .tint(Theme.Colors.accent)
                    .foregroundStyle(Theme.Colors.background)

                    Button("Use in-app only") {
                        model.settings.isGlobalCaptureEnabled = false
                        isPresented = false
                    }
                    .buttonStyle(.glass)
                }

                Text("In-app only is a real choice, not a downgrade — the speed test, "
                    + "practice pad and every visualisation work without any permission.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Theme.Spacing.page)
        .frame(width: 620)
        .background(Theme.Colors.background)
    }

    private func point(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(Theme.Typography.title).foregroundStyle(Theme.Colors.primaryText)
            Text(detail)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.mutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

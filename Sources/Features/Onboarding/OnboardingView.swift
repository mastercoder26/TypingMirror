import SwiftUI
import TypingMirrorKit

/// First run. Explains what is measured before asking for anything.
struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Tk.S.s6) {
            VStack(alignment: .leading, spacing: Tk.S.s2) {
                Text("TypingMirror")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(Tk.C.textPrimary)
                Text("It measures how you type, not what you type.")
                    .font(Tk.F.title)
                    .foregroundStyle(Tk.C.textSecondary)
            }

            VStack(alignment: .leading, spacing: Tk.S.s4) {
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

            Divider().overlay(Tk.C.strokeSoft)

            VStack(alignment: .leading, spacing: Tk.S.s3) {
                Text("Watch typing in other apps?")
                    .font(Tk.F.title)
                    .foregroundStyle(Tk.C.textPrimary)
                Text("This is what makes it possible to compare coding against writing against "
                    + "messaging. It needs Input Monitoring permission, and you can turn it "
                    + "off at any time.")
                    .font(Tk.F.body)
                    .foregroundStyle(Tk.C.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: Tk.S.s3) {
                    Button("Turn on and grant access") {
                        model.settings.isGlobalCaptureEnabled = true
                        model.coordinator?.requestPermission()
                        isPresented = false
                    }
                    .buttonStyle(.glassProminent)
                    .tint(Tk.C.accent)
                    .foregroundStyle(Tk.C.bgBase)

                    Button("Use in-app only") {
                        model.settings.isGlobalCaptureEnabled = false
                        isPresented = false
                    }
                    .buttonStyle(.glass)
                }

                Text("In-app only is a real choice, not a downgrade — the speed test, "
                    + "practice pad and every visualisation work without any permission.")
                    .font(Tk.F.caption)
                    .foregroundStyle(Tk.C.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Tk.S.s7)
        .frame(width: 620)
        .background(Tk.C.bgBase)
    }

    private func point(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(Tk.F.title).foregroundStyle(Tk.C.textPrimary)
            Text(detail)
                .font(Tk.F.body)
                .foregroundStyle(Tk.C.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

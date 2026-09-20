import ApplicationServices
import AppKit
import Foundation

/// Permission checks and the deep links that let the user grant them.
public enum AccessibilityPermission {
    public static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Shows the system prompt. There is no Info.plist usage string for this, so
    /// the app's own onboarding has to carry the explanation.
    public static func request() {
        // The constant itself is a mutable global, so the documented literal is
        // used instead to stay concurrency-safe.
        let options = ["AXTrustedCheckOptionPrompt": true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    public static func openSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ) else { return }
        NSWorkspace.shared.open(url)
    }
}

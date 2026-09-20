import AppKit
import ApplicationServices
import Foundation
import IOKit.hid

/// The permissions a keyboard event tap needs, and how to ask for them.
///
/// Two separate TCC services are involved and they are easy to confuse:
/// Accessibility governs controlling other apps, while **Input Monitoring**
/// governs observing keystrokes. A listen-only keyboard tap needs Input
/// Monitoring; granting only Accessibility leaves `tapCreate` returning nil with
/// no explanation.
public enum CapturePermissions {
    public enum Status: Equatable, Sendable {
        case granted
        case denied
        case undetermined
    }

    public static var accessibility: Status {
        AXIsProcessTrusted() ? .granted : .denied
    }

    public static var inputMonitoring: Status {
        switch IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) {
        case kIOHIDAccessTypeGranted: .granted
        case kIOHIDAccessTypeDenied: .denied
        default: .undetermined
        }
    }

    /// Both are requested because which one the system actually enforces for
    /// keyboard taps has varied between releases, and asking for the wrong one
    /// alone fails silently.
    public static func requestAll() {
        if inputMonitoring != .granted {
            // Shows the system prompt the first time; a no-op once decided.
            _ = IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
        }
        if accessibility != .granted {
            _ = AXIsProcessTrustedWithOptions(
                ["AXTrustedCheckOptionPrompt": true] as CFDictionary
            )
        }
    }

    public enum Pane: String {
        case inputMonitoring = "Privacy_ListenEvent"
        case accessibility = "Privacy_Accessibility"
    }

    public static func openSettings(_ pane: Pane) {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?\(pane.rawValue)"
        ) else { return }
        NSWorkspace.shared.open(url)
    }

    /// What to tell the user, naming the specific switch that is missing.
    public static var missingDescription: String? {
        switch (inputMonitoring, accessibility) {
        case (.granted, _):
            nil
        case (_, .granted):
            "Input Monitoring is still needed. Accessibility alone does not let an "
                + "app observe keystrokes."
        default:
            "Input Monitoring permission is needed so TypingMirror can see key timing."
        }
    }
}

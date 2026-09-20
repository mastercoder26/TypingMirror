import SwiftUI

/// Hosts the keystroke capture view and keeps it first responder while active.
struct KeystrokeCaptureView: NSViewRepresentable {
    var isActive: Bool
    var onKeystroke: (Keystroke) -> Void

    func makeNSView(context: Context) -> KeystrokeNSView {
        let view = KeystrokeNSView()
        view.onKeystroke = onKeystroke
        view.wantsFocus = isActive
        return view
    }

    func updateNSView(_ view: KeystrokeNSView, context: Context) {
        view.onKeystroke = onKeystroke
        view.wantsFocus = isActive

        if isActive {
            view.claimFocusIfWanted()
        } else if let window = view.window, window.firstResponder === view {
            window.makeFirstResponder(nil)
        }
    }
}

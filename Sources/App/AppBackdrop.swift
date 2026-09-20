import SwiftUI

/// The app-wide backdrop: one flat surface, no gradients.
///
/// Glass reads against it through its own edge and hairline, not through a
/// decorative wash behind it.
public struct AppBackdrop: View {
    public init() {}

    public var body: some View {
        Tk.C.bgBase.ignoresSafeArea()
    }
}

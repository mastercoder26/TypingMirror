import SwiftUI

/// The shared background behind the app's glass panels.
public struct AppBackdrop: View {
    public init() {}

    public var body: some View {
        Theme.Colors.background.ignoresSafeArea()
    }
}

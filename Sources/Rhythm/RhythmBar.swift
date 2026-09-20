import SwiftUI

/// Static rhythm trace for a finished session.
public struct RhythmBar: View {
    private let samples: [Double]
    private let height: CGFloat

    public init(samples: [Double], height: CGFloat = 96) {
        self.samples = samples
        self.height = height
    }

    public var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
            var context = context
            RhythmRenderer.draw(into: &context, size: size, samples: samples)
        }
        .frame(height: height)
        .accessibilityLabel("Typing rhythm over the session")
    }
}

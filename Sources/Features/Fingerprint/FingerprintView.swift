import SwiftUI
import TypingMirrorKit

/// A day's typing rendered as a mark.
///
/// Geometry carries the meaning — petal count, radius, wobble and notches each
/// track a specific feature — so the image stays legible without any colour and
/// two similar days look genuinely similar.
struct FingerprintView: View {
    let parameters: FingerprintParameters
    var lineWidthScale: Double = 1

    var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let maxRadius = min(size.width, size.height) / 2 * 0.92
            var rng = SplitMix64(seed: parameters.seed)

            drawHourRings(&context, center: center, maxRadius: maxRadius)
            drawPetals(&context, center: center, maxRadius: maxRadius, rng: &rng)
            drawCore(&context, center: center, maxRadius: maxRadius)
        }
        .drawingGroup()
        .accessibilityLabel("Typing fingerprint for the day")
    }

    /// One ring per hour; its weight is that hour's share of the day's typing, so
    /// the shape encodes *when* you typed as well as how.
    private func drawHourRings(
        _ context: inout GraphicsContext,
        center: CGPoint,
        maxRadius: Double
    ) {
        for hour in 0..<24 {
            let share = parameters.hourlyShare[hour]
            let radius = maxRadius * parameters.radiusFraction * (0.24 + Double(hour) / 24 * 0.76)
            let isQuiet = share < 0.001
            let sweep = isQuiet ? 0.12 : 0.25 + share * 5.5

            var path = Path()
            let start = Angle.degrees(Double(hour) / 24 * 360 - 90)
            path.addArc(
                center: center,
                radius: radius,
                startAngle: start,
                endAngle: start + .radians(min(sweep, .pi * 1.8)),
                clockwise: false
            )
            context.stroke(
                path,
                with: .color(Tk.C.viz(isQuiet ? 0.12 : 0.35 + share * 2.5)),
                lineWidth: isQuiet ? 0.6 : parameters.strokeWidth * lineWidthScale
            )
        }
    }

    private func drawPetals(
        _ context: inout GraphicsContext,
        center: CGPoint,
        maxRadius: Double,
        rng: inout SplitMix64
    ) {
        let outer = maxRadius * parameters.radiusFraction
        for petal in 0..<parameters.petalCount {
            // Only the phase jitter comes from the seed; the structure does not.
            let jitter = (Double(rng.next() % 1000) / 1000 - 0.5) * parameters.wobble
            let angle = Double(petal) / Double(parameters.petalCount) * 2 * .pi
            let tip = CGPoint(
                x: center.x + cos(angle) * (outer + jitter),
                y: center.y + sin(angle) * (outer + jitter)
            )
            let control = CGPoint(
                x: center.x + cos(angle + 0.32) * outer * 0.55,
                y: center.y + sin(angle + 0.32) * outer * 0.55
            )

            var path = Path()
            path.move(to: center)
            path.addQuadCurve(to: tip, control: control)
            path.addQuadCurve(
                to: center,
                control: CGPoint(
                    x: center.x + cos(angle - 0.32) * outer * 0.55,
                    y: center.y + sin(angle - 0.32) * outer * 0.55
                )
            )
            context.stroke(
                path,
                with: .color(Tk.C.viz(parameters.brightness).opacity(0.55)),
                lineWidth: parameters.strokeWidth * 0.8 * lineWidthScale
            )
        }
    }

    /// A solid heart whose size is inverse to how much was rewritten, notched once
    /// per correction.
    private func drawCore(
        _ context: inout GraphicsContext,
        center: CGPoint,
        maxRadius: Double
    ) {
        let radius = maxRadius * parameters.coreFraction
        guard radius > 1 else { return }

        var path = Path()
        for side in 0...parameters.coreSides {
            let angle = Double(side) / Double(parameters.coreSides) * 2 * .pi - .pi / 2
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
            side == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        path.closeSubpath()
        context.fill(path, with: .color(Tk.C.viz(parameters.brightness)))

        for notch in 0..<min(parameters.notchCount, 40) {
            let angle = Double(notch) / Double(max(1, min(parameters.notchCount, 40))) * 2 * .pi
            var tick = Path()
            tick.move(to: CGPoint(
                x: center.x + cos(angle) * radius * 1.25,
                y: center.y + sin(angle) * radius * 1.25
            ))
            tick.addLine(to: CGPoint(
                x: center.x + cos(angle) * radius * 1.5,
                y: center.y + sin(angle) * radius * 1.5
            ))
            context.stroke(tick, with: .color(Tk.C.textTertiary), lineWidth: 1)
        }
    }
}

import AppKit
import Foundation

// Draws the app icon: a rhythm trace reflected about a centre line.
//
// Monochrome and geometric on purpose, matching the app, where data is encoded
// by brightness rather than hue. Only five bars so the silhouette still reads at
// 16pt, where finer detail would turn to mush.

/// Each bar's extent above and below the centre line, plus its brightness.
/// The reflection is deliberately imperfect — the lower half is the mirror, not
/// a copy.
let bars: [(up: Double, down: Double, white: Double)] = [
    (0.34, 0.22, 0.55),
    (0.62, 0.44, 0.72),
    (1.00, 0.70, 1.00),
    (0.50, 0.86, 0.82),
    (0.26, 0.36, 0.62),
]

func render(size: Int) -> Data {
    let s = Double(size)
    let scale = 4  // supersample, then let the image resize smooth the curves
    let px = size * scale
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.scaleBy(x: Double(scale), y: Double(scale))

    // macOS icons carry their own rounded-rect, inset from the canvas edge.
    let inset = s * 0.055
    let rect = CGRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let radius = rect.width * 0.2237  // the standard macOS squircle proportion

    let shape = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    ctx.addPath(shape)
    ctx.setFillColor(CGColor(red: 0x0E / 255, green: 0x0E / 255, blue: 0x10 / 255, alpha: 1))
    ctx.fillPath()

    // A hairline defines the edge against a dark desktop, the same way every
    // glass panel in the app does.
    ctx.addPath(shape)
    ctx.setStrokeColor(CGColor(gray: 1, alpha: 0.12))
    ctx.setLineWidth(max(s / 128, 0.5))
    ctx.strokePath()

    let barWidth = rect.width * 0.104
    let gap = rect.width * 0.062
    let totalWidth = barWidth * Double(bars.count) + gap * Double(bars.count - 1)
    var x = rect.midX - totalWidth / 2
    let centreY = rect.midY
    let unit = rect.height * 0.285
    let capRadius = barWidth / 2
    // Keeps the two halves visually distinct rather than reading as one bar.
    let split = rect.height * 0.018

    for bar in bars {
        for (extent, isUp) in [(bar.up, true), (bar.down, false)] {
            let height = unit * extent
            guard height > capRadius else { continue }
            let y = isUp ? centreY + split : centreY - split - height
            let barRect = CGRect(x: x, y: y, width: barWidth, height: height)
            ctx.addPath(
                CGPath(roundedRect: barRect, cornerWidth: capRadius, cornerHeight: capRadius, transform: nil)
            )
            // The reflection sits back a little, so the eye reads top as the
            // typing and bottom as its echo.
            ctx.setFillColor(CGColor(gray: 1, alpha: bar.white * (isUp ? 1.0 : 0.58)))
            ctx.fillPath()
        }
        x += barWidth + gap
    }

    NSGraphicsContext.restoreGraphicsState()

    // Downsample to the requested size.
    let full = NSImage(size: NSSize(width: px, height: px))
    full.addRepresentation(bitmap)
    let out = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: out)
    NSGraphicsContext.current!.imageInterpolation = .high
    full.draw(in: CGRect(x: 0, y: 0, width: s, height: s))
    NSGraphicsContext.restoreGraphicsState()

    return out.representation(using: .png, properties: [:])!
}

let target = CommandLine.arguments[1]
// The full set macOS asks for, as 1x/2x pairs.
let sizes: [(Int, String)] = [
    (16, "icon_16x16.png"), (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"), (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"), (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"), (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"), (1024, "icon_512x512@2x.png"),
]
for (size, name) in sizes {
    try render(size: size).write(to: URL(fileURLWithPath: target + "/" + name))
}
print("wrote \(sizes.count) images")

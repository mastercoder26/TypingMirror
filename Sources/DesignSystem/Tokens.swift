import SwiftUI

/// Design tokens. No feature view should contain a literal color, font size,
/// or padding value — everything reads from here.
public enum Tk {}

// MARK: - Color

public extension Tk {
    enum C {
        // Surfaces. Not pure black, so glass edges and hairlines stay legible.
        public static let bgBase = Color(hex: 0x0E0E10)
        public static let bgRaised = Color(hex: 0x121216)
        public static let bgSunken = Color(hex: 0x060608)

        public static let strokeSoft = Color.white.opacity(0.06)
        public static let strokeHard = Color.white.opacity(0.12)

        // Explicit text ramp. Never use .secondary/.tertiary — those are tuned
        // for standard materials and read muddy on dark glass.
        public static let textPrimary = Color(hex: 0xF2F2F5)
        public static let textSecondary = Color(hex: 0x9A9AA6)
        public static let textTertiary = Color(hex: 0x646470)

        // One functional accent, near-white. Emphasis comes from type weight and
        // size, never from color. Color is reserved for meaning.
        public static let accent = Color(hex: 0xE8E8ED)
        public static let accentDim = Color(hex: 0x8A8A93)

        // Typing states
        public static let correct = Color(hex: 0x8B8B99)
        public static let pending = Color(hex: 0x3A3A44)
        public static let incorrect = Color(hex: 0xFF5C5C)
        public static let corrected = Color(hex: 0xE0A44B)

        // Neutral luminance ramp. Data is encoded by brightness, not hue, so the
        // charts stay readable and carry no decorative color.
        public static let vizRamp: [Color] = [
            Color(hex: 0x1A1A1D), Color(hex: 0x2C2C31), Color(hex: 0x454550),
            Color(hex: 0x6C6C79), Color(hex: 0x9C9CA8), Color(hex: 0xD6D6DD),
        ]

        /// Samples `vizRamp` at `t` in 0...1 with linear interpolation between stops.
        public static func viz(_ t: Double) -> Color {
            let clamped = min(max(t, 0), 1)
            let scaled = clamped * Double(vizRamp.count - 1)
            let index = min(Int(scaled), vizRamp.count - 2)
            return vizRamp[index].mix(with: vizRamp[index + 1], by: scaled - Double(index))
        }
    }
}

// MARK: - Typography

public extension Tk {
    enum F {
        public static let display = Font.system(size: 44, weight: .medium).monospacedDigit()
        public static let metric = Font.system(size: 26, weight: .medium).monospacedDigit()
        public static let metricSm = Font.system(size: 17, weight: .medium).monospacedDigit()
        public static let title = Font.system(size: 15, weight: .semibold)
        public static let body = Font.system(size: 13)
        public static let label = Font.system(size: 11, weight: .medium)
        public static let caption = Font.system(size: 10, weight: .medium)
        public static let mono = Font.system(size: 13, design: .monospaced)
        public static let monoSm = Font.system(size: 10, design: .monospaced)
        public static let stream = Font.system(size: 28, weight: .regular, design: .monospaced)
    }
}

// MARK: - Layout

public extension Tk {
    /// 4pt spacing grid.
    enum S {
        public static let s0: CGFloat = 2
        public static let s1: CGFloat = 4
        public static let s2: CGFloat = 8
        public static let s3: CGFloat = 12
        public static let s4: CGFloat = 16
        public static let s5: CGFloat = 24
        public static let s6: CGFloat = 32
        public static let s7: CGFloat = 48
    }

    enum R {
        public static let xs: CGFloat = 6
        public static let sm: CGFloat = 10
        public static let md: CGFloat = 14
        public static let lg: CGFloat = 20
        public static let xl: CGFloat = 28
    }

    enum Z {
        public static let liftRadius: CGFloat = 12
        public static let liftY: CGFloat = 4
        public static let liftOpacity: Double = 0.34
        public static let floatRadius: CGFloat = 34
        public static let floatY: CGFloat = 14
        public static let floatOpacity: Double = 0.48
    }

    enum L {
        public static let sidebarWidth: CGFloat = 208
        public static let contentMaxWidth: CGFloat = 1100
        public static let windowMinWidth: CGFloat = 1040
        public static let windowMinHeight: CGFloat = 680
        public static let statTileMinWidth: CGFloat = 152
    }
}

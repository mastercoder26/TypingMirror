import SwiftUI

/// Shared colors, type sizes and spacing for the dark interface.
public enum Theme {}

// MARK: - Color

public extension Theme {
    enum Colors {
        // Surfaces. Not pure black, so glass edges and hairlines stay legible.
        public static let background = Color(hex: 0x0E0E10)
        public static let raisedBackground = Color(hex: 0x121216)
        public static let insetBackground = Color(hex: 0x060608)

        public static let subtleBorder = Color.white.opacity(0.06)
        public static let strongBorder = Color.white.opacity(0.12)

        // Text colors are tuned for the dark backdrop.
        public static let primaryText = Color(hex: 0xF2F2F5)
        public static let secondaryText = Color(hex: 0xA5A5AF)
        public static let mutedText = Color(hex: 0x81818D)

        // A neutral accent leaves red and amber for typing feedback.
        public static let accent = Color(hex: 0xE8E8ED)
        public static let mutedAccent = Color(hex: 0x8A8A93)

        // Typing states
        public static let correct = Color(hex: 0x8B8B99)
        public static let pending = Color(hex: 0x3A3A44)
        public static let incorrect = Color(hex: 0xFF5C5C)
        public static let corrected = Color(hex: 0xE0A44B)

        // Chart values increase in brightness.
        public static let chartRamp: [Color] = [
            Color(hex: 0x1A1A1D), Color(hex: 0x2C2C31), Color(hex: 0x454550),
            Color(hex: 0x6C6C79), Color(hex: 0x9C9CA8), Color(hex: 0xD6D6DD),
        ]

        /// Samples `chartRamp` at `t` in 0...1 with linear interpolation between stops.
        public static func chartColor(_ t: Double) -> Color {
            let clamped = min(max(t, 0), 1)
            let scaled = clamped * Double(chartRamp.count - 1)
            let index = min(Int(scaled), chartRamp.count - 2)
            return chartRamp[index].mix(with: chartRamp[index + 1], by: scaled - Double(index))
        }
    }
}

// MARK: - Typography

public extension Theme {
    enum Typography {
        public static let pageTitle = Font.system(size: 34, weight: .semibold)
        public static let headlineMetric = Font.system(size: 76, weight: .medium).monospacedDigit()
        public static let display = Font.system(size: 44, weight: .medium).monospacedDigit()
        public static let metric = Font.system(size: 26, weight: .medium).monospacedDigit()
        public static let smallMetric = Font.system(size: 17, weight: .medium).monospacedDigit()
        public static let title = Font.system(size: 15, weight: .semibold)
        public static let body = Font.system(size: 13)
        public static let label = Font.system(size: 11, weight: .medium)
        public static let caption = Font.system(size: 11, weight: .medium)
        public static let monospaced = Font.system(size: 13, design: .monospaced)
        public static let smallMonospaced = Font.system(size: 11, design: .monospaced)
        public static let stream = Font.system(size: 28, weight: .regular, design: .monospaced)
    }
}

// MARK: - Layout

public extension Theme {
    /// Shared spacing, with a 2pt step for tight labels.
    enum Spacing {
        public static let tiny: CGFloat = 2
        public static let tight: CGFloat = 4
        public static let small: CGFloat = 8
        public static let regular: CGFloat = 12
        public static let medium: CGFloat = 16
        public static let large: CGFloat = 24
        public static let extraLarge: CGFloat = 32
        public static let page: CGFloat = 48
    }

    enum Radius {
        public static let extraSmall: CGFloat = 6
        public static let small: CGFloat = 10
        public static let medium: CGFloat = 14
        public static let large: CGFloat = 20
        public static let extraLarge: CGFloat = 28
    }

    enum Shadows {
        public static let liftRadius: CGFloat = 12
        public static let liftY: CGFloat = 4
        public static let liftOpacity: Double = 0.34
        public static let floatRadius: CGFloat = 34
        public static let floatY: CGFloat = 14
        public static let floatOpacity: Double = 0.48
    }

    enum Layout {
        public static let sidebarWidth: CGFloat = 208
        public static let contentMaxWidth: CGFloat = 1100
        public static let windowMinWidth: CGFloat = 1040
        public static let windowMinHeight: CGFloat = 680
        public static let statTileMinWidth: CGFloat = 152
    }
}

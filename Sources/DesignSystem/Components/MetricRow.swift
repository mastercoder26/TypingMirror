import SwiftUI

/// A labeled value. Dividers belong to the row, so each metric stays borderless.
public struct Metric: View {
    private let label: String
    private let value: String
    private let unit: String?
    private let prominent: Bool

    public init(_ label: String, value: String, unit: String? = nil, prominent: Bool = false) {
        self.label = label
        self.value = value
        self.unit = unit
        self.prominent = prominent
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text(label.uppercased())
                .font(Theme.Typography.label)
                .tracking(0.6)
                .foregroundStyle(Theme.Colors.mutedText)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(prominent ? Theme.Typography.display : Theme.Typography.metric)
                    .foregroundStyle(Theme.Colors.primaryText)
                    .contentTransition(.numericText())
                if let unit {
                    Text(unit)
                        .font(prominent ? Theme.Typography.smallMetric : Theme.Typography.label)
                        .foregroundStyle(Theme.Colors.mutedText)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A horizontal band of metrics separated by hairlines.
public struct MetricRow<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 0) {
            content
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.Colors.subtleBorder)
                .frame(height: 1)
        }
        .padding(.top, Theme.Spacing.medium)
    }
}

/// Vertical hairline placed between metrics.
public struct MetricDivider: View {
    public init() {}

    public var body: some View {
        Rectangle()
            .fill(Theme.Colors.subtleBorder)
            .frame(width: 1)
            .frame(maxHeight: .infinity)
            .padding(.vertical, Theme.Spacing.tight)
            .padding(.horizontal, Theme.Spacing.medium)
    }
}

import SwiftUI

/// One figure in a metric row: caption above value, no container of its own.
///
/// Deliberately borderless. A row of bordered cards inside an already-bordered
/// panel is the single most recognisable generated-UI pattern; hairline dividers
/// carry the same separation with none of the visual noise.
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
        VStack(alignment: .leading, spacing: Tk.S.s2) {
            Text(label.uppercased())
                .font(Tk.F.label)
                .tracking(0.6)
                .foregroundStyle(Tk.C.textTertiary)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(prominent ? Tk.F.display : Tk.F.metric)
                    .foregroundStyle(Tk.C.textPrimary)
                    .contentTransition(.numericText())
                if let unit {
                    Text(unit)
                        .font(prominent ? Tk.F.metricSm : Tk.F.label)
                        .foregroundStyle(Tk.C.textTertiary)
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
                .fill(Tk.C.strokeSoft)
                .frame(height: 1)
        }
        .padding(.top, Tk.S.s4)
    }
}

/// Vertical hairline placed between metrics.
public struct MetricDivider: View {
    public init() {}

    public var body: some View {
        Rectangle()
            .fill(Tk.C.strokeSoft)
            .frame(width: 1)
            .frame(maxHeight: .infinity)
            .padding(.vertical, Tk.S.s1)
            .padding(.horizontal, Tk.S.s4)
    }
}

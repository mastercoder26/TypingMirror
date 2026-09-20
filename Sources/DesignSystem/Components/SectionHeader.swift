import SwiftUI

public struct SectionHeader: View {
    private let title: String
    private let trailing: String?

    public init(_ title: String, trailing: String? = nil) {
        self.title = title
        self.trailing = trailing
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(Tk.F.label)
                .tracking(0.6)
                .foregroundStyle(Tk.C.textTertiary)
            Spacer(minLength: Tk.S.s3)
            if let trailing {
                Text(trailing)
                    .font(Tk.F.caption)
                    .foregroundStyle(Tk.C.textTertiary)
            }
        }
    }
}

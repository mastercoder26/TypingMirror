import Foundation

enum SidebarItem: String, CaseIterable, Identifiable, Hashable {
    case today

    var id: String { rawValue }
    var title: String { "Today" }
    var symbol: String { "square.grid.2x2" }
    var section: String { "Today" }
    static let sections = ["Today"]
}

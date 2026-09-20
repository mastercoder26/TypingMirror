import Foundation

enum SidebarItem: String, CaseIterable, Identifiable, Hashable {
    case today
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: "Today"
        case .settings: "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .today: "square.grid.2x2"
        case .settings: "gearshape"
        }
    }

    var section: String {
        switch self {
        case .today: "Today"
        case .settings: "App"
        }
    }

    static let sections = ["Today", "App"]
}

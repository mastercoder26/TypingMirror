import Foundation

enum SidebarItem: String, CaseIterable, Identifiable, Hashable {
    case today
    case sessions
    case speedTest
    case practice
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: "Today"
        case .sessions: "Sessions"
        case .speedTest: "Speed test"
        case .practice: "Practice pad"
        case .settings: "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .today: "square.grid.2x2"
        case .sessions: "list.bullet"
        case .speedTest: "timer"
        case .practice: "keyboard"
        case .settings: "gearshape"
        }
    }

    var section: String {
        switch self {
        case .today: "Today"
        case .sessions: "Analyse"
        case .speedTest, .practice: "Practice"
        case .settings: "App"
        }
    }

    static let sections = ["Today", "Analyse", "Practice", "App"]
}

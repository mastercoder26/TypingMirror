import Foundation

public enum SessionCategory: String, Sendable, CaseIterable, Identifiable {
    case coding
    case writing
    case messaging
    case homework
    case test
    case mixed

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .coding: "Coding"
        case .writing: "Writing"
        case .messaging: "Messaging"
        case .homework: "Homework"
        case .test: "Typing test"
        case .mixed: "Mixed"
        }
    }
}

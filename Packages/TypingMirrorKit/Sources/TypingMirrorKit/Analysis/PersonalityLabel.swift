import Foundation

public enum PersonalityLabel: String, Sendable, CaseIterable, Identifiable {
    case steady
    case burstHeavy
    case careful
    case rapidEditing

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .steady: "Steady rhythm"
        case .burstHeavy: "Fast bursts"
        case .careful: "Careful"
        case .rapidEditing: "Rapid editing"
        }
    }

    public var symbol: String {
        switch self {
        case .steady: "metronome"
        case .burstHeavy: "bolt"
        case .careful: "scope"
        case .rapidEditing: "pencil"
        }
    }

    /// Labels that cannot both be true of the same session.
    ///
    /// Constant rewriting is not an even rhythm, so `steady` and `rapidEditing`
    /// are mutually exclusive just as `steady` and `burstHeavy` are.
    static let contradictions: [(PersonalityLabel, PersonalityLabel)] = [
        (.steady, .burstHeavy),
        (.steady, .rapidEditing),
        (.careful, .rapidEditing),
    ]
}

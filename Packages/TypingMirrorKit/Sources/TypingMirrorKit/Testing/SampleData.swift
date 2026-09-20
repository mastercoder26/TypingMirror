import Foundation

/// Deterministic sample sessions.
///
/// Every screen is built against these before any real capture exists, so that
/// layout and typography are designed around realistic numbers rather than
/// round placeholders.
public enum SampleData {
    public struct Recipe: Sendable {
        let profile: SyntheticKeystrokeGenerator.Profile
        let category: SessionCategory
        let appName: String?
        let keystrokes: Int
        let hoursAgo: Double
        let seed: UInt64
    }

    static let recipes: [Recipe] = [
        Recipe(profile: .bursty, category: .coding, appName: "Xcode",
               keystrokes: 5_400, hoursAgo: 2, seed: 101),
        Recipe(profile: .careful, category: .homework, appName: "Pages",
               keystrokes: 3_100, hoursAgo: 7, seed: 202),
        Recipe(profile: .editHeavy, category: .writing, appName: "Obsidian",
               keystrokes: 4_200, hoursAgo: 26, seed: 303),
        Recipe(profile: .steady, category: .test, appName: nil,
               keystrokes: 900, hoursAgo: 30, seed: 404),
        Recipe(profile: .steady, category: .messaging, appName: "Messages",
               keystrokes: 1_600, hoursAgo: 52, seed: 505),
        Recipe(profile: .bursty, category: .coding, appName: "Ghostty",
               keystrokes: 2_800, hoursAgo: 74, seed: 606),
    ]

    public static func sessions(now: Date = Date()) -> [TypingSession] {
        recipes.map { recipe in
            var generator = SyntheticKeystrokeGenerator(profile: recipe.profile, seed: recipe.seed)
            let events = generator.generate(count: recipe.keystrokes)
            return TypingSession(
                startedAt: now.addingTimeInterval(-recipe.hoursAgo * 3_600),
                category: recipe.category,
                appName: recipe.appName,
                metrics: SessionMetricsBuilder.build(events: events)
            )
        }
    }

    /// The session the detail screen opens on by default.
    public static func featured(now: Date = Date()) -> TypingSession {
        sessions(now: now)[0]
    }
}

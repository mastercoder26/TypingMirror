import Foundation

/// Maps an app to the kind of typing usually done in it.
///
/// Bundle identifier only. Window titles and URLs would classify far better and
/// are deliberately never read — that would be the single largest privacy
/// regression available here, and better auto-tagging is not worth it.
public enum AppCategoryRules {
    private static let table: [String: SessionCategory] = [
        "com.apple.dt.Xcode": .coding,
        "com.microsoft.VSCode": .coding,
        "com.todesktop.230313mzl4w4u92": .coding,
        "dev.zed.Zed": .coding,
        "com.apple.Terminal": .coding,
        "com.mitchellh.ghostty": .coding,
        "com.googlecode.iterm2": .coding,
        "com.jetbrains.intellij": .coding,
        "com.apple.Pages": .writing,
        "com.microsoft.Word": .writing,
        "md.obsidian": .writing,
        "com.ulyssesapp.mac": .writing,
        "notion.id": .writing,
        "com.apple.TextEdit": .writing,
        "com.apple.MobileSMS": .messaging,
        "com.tinyspeck.slackmacgap": .messaging,
        "com.hnc.Discord": .messaging,
        "com.apple.mail": .messaging,
    ]

    public static func category(for bundleID: String?) -> SessionCategory {
        guard let bundleID else { return .mixed }
        return table[bundleID] ?? .mixed
    }

    public static var known: [String: SessionCategory] { table }
}

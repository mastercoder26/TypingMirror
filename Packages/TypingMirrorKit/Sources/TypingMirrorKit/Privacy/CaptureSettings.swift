import Foundation

/// User-facing capture configuration.
public struct CaptureSettings: Sendable, Codable, Equatable {
    public var tier: PrivacyTier
    public var isGlobalCaptureEnabled: Bool
    /// Bundle identifiers never observed, whatever the tier.
    public var excludedBundleIDs: Set<String>
    public var wordRetentionDays: Int

    public static let defaultExclusions: Set<String> = [
        "com.apple.keychainaccess",
        "com.1password.1password",
        "com.agilebits.onepassword7",
        "com.apple.Passwords",
        "com.apple.MobileSMS",
        "com.apple.mail",
    ]

    /// Rhythm only, global capture off. Nothing is observed until asked for.
    public static let `default` = CaptureSettings(
        tier: .rhythmOnly,
        isGlobalCaptureEnabled: false,
        excludedBundleIDs: defaultExclusions,
        wordRetentionDays: 14
    )

    public func allows(bundleID: String?) -> Bool {
        guard let bundleID else { return true }
        return !excludedBundleIDs.contains(bundleID)
    }
}

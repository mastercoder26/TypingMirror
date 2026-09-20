import Testing
@testable import TypingMirrorKit

@Suite("Word capture filter")
struct WordCaptureFilterTests {
    @Test("ordinary prose is kept", arguments: [
        "because", "language", "mountain", "don't", "well-known",
    ])
    func keepsProse(_ word: String) {
        #expect(WordCaptureFilter.isSafeToStore(word))
    }

    @Test("anything credential-shaped is dropped", arguments: [
        "hunter2",            // digits
        "Tr0ub4dor",          // digits and mixed case
        "sk-abc-secret",      // API key shape
        "user@example.com",   // address
        "~/Documents/tax",    // path
        "xKcdRandom",         // internal capitals
        "zxcvbnm",            // no vowels
        "supercalifragilisticexpialidocious", // over length
        "ok",                 // under length
    ])
    func dropsSensitiveShapes(_ word: String) {
        #expect(!WordCaptureFilter.isSafeToStore(word))
    }

    @Test("a leading capital is fine, since sentences start that way")
    func allowsSentenceCase() {
        #expect(WordCaptureFilter.isSafeToStore("Because"))
    }
}

@Suite("Capture settings")
struct CaptureSettingsTests {
    @Test("the default stores no text and observes nothing globally")
    func defaultIsPrivate() {
        let settings = CaptureSettings.default
        #expect(settings.tier == .rhythmOnly)
        #expect(!settings.tier.storesText)
        #expect(!settings.isGlobalCaptureEnabled)
    }

    @Test("password managers are excluded out of the box")
    func excludesSecretHolders() {
        #expect(!CaptureSettings.default.allows(bundleID: "com.1password.1password"))
        #expect(!CaptureSettings.default.allows(bundleID: "com.apple.keychainaccess"))
        #expect(CaptureSettings.default.allows(bundleID: "com.apple.dt.Xcode"))
    }

    @Test("only the lexical tier admits to storing text")
    func onlyLexicalStoresText() {
        #expect(!PrivacyTier.rhythmOnly.storesText)
        #expect(!PrivacyTier.wordShapes.storesText)
        #expect(PrivacyTier.lexical.storesText)
    }
}

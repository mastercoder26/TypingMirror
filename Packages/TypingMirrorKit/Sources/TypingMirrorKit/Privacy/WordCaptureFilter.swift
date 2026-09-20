import Foundation

/// Decides whether a typed word may be stored under the lexical tier.
///
/// The bias is deliberately toward discarding: losing an ordinary word costs a
/// row in a list, while keeping one secret costs the user's trust. Anything
/// shaped like a credential, identifier, address or code is dropped.
public enum WordCaptureFilter {
    public static let minimumLength = 3
    public static let maximumLength = 20

    public static func isSafeToStore(_ word: String) -> Bool {
        let trimmed = word.trimmingCharacters(in: .punctuationCharacters)
        guard trimmed.count >= minimumLength, trimmed.count <= maximumLength else { return false }

        // Digits are the strongest single signal of an identifier, code, address
        // or password rather than prose.
        guard !trimmed.contains(where: \.isNumber) else { return false }
        guard trimmed.allSatisfy({ $0.isLetter || $0 == "'" || $0 == "-" }) else { return false }
        guard !looksLikeAddress(trimmed) else { return false }
        guard hasWordLikeParts(trimmed) else { return false }
        guard !hasUnusualCasing(trimmed) else { return false }
        guard !hasHighEntropy(trimmed) else { return false }
        return true
    }

    /// Compound words carry at most one hyphen and every part reads like a word.
    /// Multi-segment tokens such as `sk-abc-secret` are key-shaped, not prose.
    private static func hasWordLikeParts(_ word: String) -> Bool {
        let parts = word.split(separator: "-")
        guard parts.count <= 2 else { return false }
        return parts.allSatisfy { part in
            part.count >= 2 && part.lowercased().contains(where: { "aeiouy".contains($0) })
        }
    }

    private static func looksLikeAddress(_ word: String) -> Bool {
        word.contains("@") || word.contains("/") || word.contains(".") || word.contains("\\")
    }

    /// Internal capitals and mixed case are typical of identifiers and generated
    /// secrets, and atypical of ordinary prose.
    private static func hasUnusualCasing(_ word: String) -> Bool {
        let body = word.dropFirst()
        return body.contains(where: \.isUppercase)
    }

    /// Prose reuses letters and leans on vowels; random strings do neither.
    private static func hasHighEntropy(_ word: String) -> Bool {
        let letters = Array(word.lowercased())
        guard letters.count >= 6 else { return false }
        let vowels = letters.count { "aeiouy".contains($0) }
        return Double(vowels) / Double(letters.count) < 0.15
    }
}

import Foundation

/// Subsequence matching with contiguity and word-boundary bonuses.
///
/// Scoring rewards runs of adjacent characters and matches that start a word, so
/// "sd" finds "Session detail" ahead of a coincidental scatter of those letters.
enum FuzzyMatch {
    static func score(query: String, candidate: String) -> Int? {
        guard !query.isEmpty else { return 0 }

        let needle = Array(query.lowercased())
        let haystack = Array(candidate.lowercased())
        var score = 0
        var needleIndex = 0
        var previousMatch = -2

        for (index, character) in haystack.enumerated() {
            guard needleIndex < needle.count, character == needle[needleIndex] else { continue }

            score += 1
            if index == previousMatch + 1 { score += 4 }
            let isWordStart = index == 0
                || haystack[index - 1] == " "
                || haystack[index - 1] == "-"
            if isWordStart { score += 6 }

            previousMatch = index
            needleIndex += 1
        }

        return needleIndex == needle.count ? score : nil
    }
}

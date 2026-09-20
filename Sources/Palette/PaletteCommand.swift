import SwiftUI

struct PaletteCommand: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let symbol: String
    let section: String
    /// Extra words the command should match on but that are not displayed.
    let keywords: [String]
    let run: @MainActor () -> Void

    init(
        id: String,
        title: String,
        subtitle: String? = nil,
        symbol: String,
        section: String,
        keywords: [String] = [],
        run: @escaping @MainActor () -> Void
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.section = section
        self.keywords = keywords
        self.run = run
    }

    var searchText: String {
        ([title, subtitle ?? ""] + keywords).joined(separator: " ")
    }
}

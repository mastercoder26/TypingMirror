import Observation
import SwiftUI

/// Backing state for the command palette.
@MainActor
@Observable
final class PaletteModel {
    var query = "" {
        didSet { selectedIndex = 0 }
    }
    var selectedIndex = 0
    var isPresented = false

    /// Rebuilt by the host whenever the underlying data changes.
    var commands: [PaletteCommand] = []

    var results: [PaletteCommand] {
        guard !query.isEmpty else { return commands }
        return commands
            .compactMap { command -> (PaletteCommand, Int)? in
                FuzzyMatch.score(query: query, candidate: command.searchText)
                    .map { (command, $0) }
            }
            .sorted { $0.1 > $1.1 }
            .map(\.0)
    }

    var selected: PaletteCommand? {
        let results = results
        guard results.indices.contains(selectedIndex) else { return results.first }
        return results[selectedIndex]
    }

    func present() {
        query = ""
        selectedIndex = 0
        isPresented = true
    }

    func dismiss() {
        isPresented = false
    }

    func moveSelection(by offset: Int) {
        let count = results.count
        guard count > 0 else { return }
        selectedIndex = (selectedIndex + offset + count) % count
    }

    func runSelected() {
        let command = selected
        dismiss()
        command?.run()
    }
}

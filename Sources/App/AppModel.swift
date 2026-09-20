import Foundation
import Observation
import SwiftData
import TypingMirrorKit

/// Owns the store, the live capture coordinator and the settings.
@MainActor
@Observable
final class AppModel {
    private(set) var sessions: [SessionRecord] = []
    private(set) var hesitations: [HesitationEntry] = []
    private(set) var storedWordCount = 0
    private(set) var loadError: String?

    var settings: CaptureSettings {
        didSet {
            SettingsStorage.save(settings)
            coordinator?.update(settings: settings)
            if !settings.tier.storesText, oldValue.tier.storesText {
                // Dropping out of the lexical tier must destroy what it collected,
                // not merely stop collecting more.
                Task { await purgeStoredWords() }
            }
        }
    }

    private(set) var coordinator: CaptureCoordinator?
    let store: SessionStore

    var days: [DailySummary] {
        DailySummaryBuilder.build(sessions: sessions.map(\.asTypingSession))
    }

    init(store: SessionStore) {
        self.store = store
        self.settings = SettingsStorage.load()
        let coordinator = CaptureCoordinator(store: store, settings: settings)
        self.coordinator = coordinator
        coordinator.onSessionSaved = { [weak self] _ in
            Task { await self?.reload() }
        }
    }

    func start() async {
        await reload()
        if settings.isGlobalCaptureEnabled {
            coordinator?.start()
        }
        await purgeExpiredWords()
    }

    func reload() async {
        do {
            sessions = try await store.sessions()
            hesitations = try await store.hesitations()
            storedWordCount = try await store.storedWordCount()
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }

    @discardableResult
    func saveSession(
        events: [TypingEvent],
        startedAt: Date,
        category: SessionCategory,
        source: CaptureSource
    ) async -> Bool {
        do {
            let saved = try await store.save(
                events: events,
                startedAt: startedAt,
                category: category,
                appName: nil,
                source: source
            )
            await reload()
            return saved != nil
        } catch {
            loadError = error.localizedDescription
            return false
        }
    }

    func recordHesitations(_ entries: [(word: String, hesitationMs: Double)]) async {
        guard settings.tier.storesText else { return }
        for entry in entries where WordCaptureFilter.isSafeToStore(entry.word) {
            try? await store.saveWord(entry.word, hesitationMs: entry.hesitationMs, isFromTest: true)
        }
        await reload()
    }

    func delete(sessionID: UUID) async {
        try? await store.delete(id: sessionID)
        await reload()
    }

    func deleteAllSessions() async {
        try? await store.deleteAllSessions()
        await reload()
    }

    func purgeStoredWords() async {
        try? await store.deleteAllWords()
        await reload()
    }

    func purgeExpiredWords() async {
        try? await store.purgeExpiredWords(retentionDays: settings.wordRetentionDays)
        await reload()
    }

    func storedWords() async -> [StoredWordEntry] {
        (try? await store.storedWords()) ?? []
    }

    func events(for id: UUID) async -> [TypingEvent] {
        (try? await store.events(for: id)) ?? []
    }

}

/// Settings live in user defaults: small, and they must be readable before the
/// store has opened.
enum SettingsStorage {
    private static let key = "capture.settings.v1"

    static func load() -> CaptureSettings {
        guard let data = UserDefaults.standard.data(forKey: key),
              let settings = try? JSONDecoder().decode(CaptureSettings.self, from: data)
        else { return .default }
        return settings
    }

    static func save(_ settings: CaptureSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

extension SessionRecord {
    /// Adapter for the aggregation helpers, which are written against the value type.
    var asTypingSession: TypingSession {
        TypingSession(
            id: id,
            startedAt: startedAt,
            category: category,
            appName: appName,
            metrics: metrics
        )
    }
}

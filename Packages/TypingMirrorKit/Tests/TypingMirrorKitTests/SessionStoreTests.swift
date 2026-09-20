import Foundation
import SwiftData
import Testing
@testable import TypingMirrorKit

@Suite("Session store")
struct SessionStoreTests {
    static func makeStore() throws -> SessionStore {
        SessionStore(modelContainer: try StoreFactory.container(inMemory: true))
    }

    static func events(count: Int = 3_000, seed: UInt64 = 5) -> [TypingEvent] {
        var generator = SyntheticKeystrokeGenerator(profile: .bursty, seed: seed)
        return generator.generate(count: count)
    }

    @Test("a saved session comes back with its metrics intact")
    func saveAndLoad() async throws {
        let store = try Self.makeStore()
        let saved = try await store.save(
            events: Self.events(),
            startedAt: Date(),
            category: .coding,
            appName: "Xcode",
            source: .global
        )

        let loaded = try await store.sessions()
        #expect(loaded.count == 1)
        #expect(loaded[0].category == .coding)
        #expect(loaded[0].appName == "Xcode")
        // Denormalised columns must survive, since charts never decode the blob.
        #expect(abs(loaded[0].metrics.grossWPM - (saved?.metrics.grossWPM ?? 0)) < 0.001)
        #expect(loaded[0].metrics.labels == saved?.metrics.labels)
        #expect(loaded[0].metrics.rhythm.count == SessionMetricsBuilder.rhythmBuckets)
    }

    @Test("the keystroke stream can be replayed after a round trip")
    func replaySurvives() async throws {
        let store = try Self.makeStore()
        let original = Self.events()
        let saved = try await store.save(
            events: original, startedAt: Date(), category: .writing,
            appName: nil, source: .practicePad
        )

        let decoded = try await store.events(for: try #require(saved?.id))
        #expect(decoded.count == original.count)
    }

    @Test("sessions too short to mean anything are not kept")
    func shortSessionsAreDiscarded() async throws {
        let store = try Self.makeStore()
        // Twenty keystrokes is below the floor at which any statistic is stable.
        let saved = try await store.save(
            events: Self.events(count: 20), startedAt: Date(),
            category: .writing, appName: nil, source: .practicePad
        )
        #expect(saved == nil)
        #expect(try await store.sessions().isEmpty)
    }

    @Test("sessions come back newest first")
    func sortedNewestFirst() async throws {
        let store = try Self.makeStore()
        let now = Date()
        for hoursAgo in [5.0, 1.0, 3.0] {
            _ = try await store.save(
                events: Self.events(count: 1_200, seed: UInt64(hoursAgo)),
                startedAt: now.addingTimeInterval(-hoursAgo * 3_600),
                category: .coding, appName: nil, source: .global
            )
        }
        let dates = try await store.sessions().map(\.startedAt)
        #expect(dates == dates.sorted(by: >))
    }

    @Test("deleting a session removes it")
    func deleteRemoves() async throws {
        let store = try Self.makeStore()
        let saved = try await store.save(
            events: Self.events(), startedAt: Date(),
            category: .coding, appName: nil, source: .global
        )
        try await store.delete(id: try #require(saved?.id))
        #expect(try await store.sessions().isEmpty)
    }

    @Test("stored words can be listed and purged")
    func wordsRoundTripAndPurge() async throws {
        let store = try Self.makeStore()
        try await store.saveWord("because", hesitationMs: 2_400, isFromTest: true)
        try await store.saveWord("because", hesitationMs: 3_100, isFromTest: true)
        try await store.saveWord("language", hesitationMs: 2_200, isFromTest: true)

        let hesitations = try await store.hesitations()
        // Repeats collapse, so the list shows habits rather than single incidents.
        #expect(hesitations.count == 2)
        #expect(hesitations.first?.word == "because")
        #expect(hesitations.first?.occurrences == 2)

        try await store.deleteAllWords()
        #expect(try await store.storedWordCount() == 0)
    }

    @Test("turning the lexical tier off destroys what it collected")
    func purgeIsDestructive() async throws {
        let store = try Self.makeStore()
        try await store.saveWord("because", hesitationMs: 2_400, isFromTest: true)
        try await store.deleteAllWords()
        #expect(try await store.storedWords().isEmpty)
    }
}

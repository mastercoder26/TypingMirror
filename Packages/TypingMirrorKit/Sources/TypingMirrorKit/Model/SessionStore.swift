import Foundation
import SwiftData

/// All persistence goes through here.
///
/// A single actor owns the model context so that writes never land on the main
/// thread mid-session, where they would stall the live rhythm graph.
@ModelActor
public actor SessionStore {
    /// Sessions below either floor are statistical noise; keeping them would fill
    /// the history with rows whose every figure is meaningless.
    public static func isWorthKeeping(_ metrics: SessionMetrics) -> Bool {
        metrics.keystrokeCount >= MetricConstants.minimumKeystrokes
            && metrics.activeMs >= MetricConstants.minimumActiveMs
    }

    @discardableResult
    public func save(
        events: [TypingEvent],
        startedAt: Date,
        category: SessionCategory,
        appName: String?,
        source: CaptureSource,
        keepReplay: Bool = true
    ) throws -> SessionRecord? {
        let metrics = SessionMetricsBuilder.build(events: events)
        guard Self.isWorthKeeping(metrics) else { return nil }

        let session = StoredSession()
        session.apply(
            metrics: metrics,
            startedAt: startedAt,
            category: category,
            appName: appName,
            source: source
        )
        if keepReplay {
            session.eventBlob = try? ChunkCodec.encode(events: events, startedAt: startedAt)
        }

        modelContext.insert(session)
        try modelContext.save()
        return session.record
    }

    public func sessions(limit: Int = 200) throws -> [SessionRecord] {
        var descriptor = FetchDescriptor<StoredSession>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor).map(\.record)
    }

    public func events(for id: UUID) throws -> [TypingEvent] {
        let descriptor = FetchDescriptor<StoredSession>(
            predicate: #Predicate { $0.id == id }
        )
        guard let blob = try modelContext.fetch(descriptor).first?.eventBlob else { return [] }
        return try ChunkCodec.decode(blob)
    }

    public func delete(id: UUID) throws {
        let descriptor = FetchDescriptor<StoredSession>(predicate: #Predicate { $0.id == id })
        for session in try modelContext.fetch(descriptor) {
            modelContext.delete(session)
        }
        try modelContext.save()
    }

    public func deleteAllSessions() throws {
        try modelContext.delete(model: StoredSession.self)
        try modelContext.save()
    }

    // MARK: Lexical capture

    public func saveWord(_ text: String, hesitationMs: Double, isFromTest: Bool) throws {
        let word = StoredWord()
        word.text = text
        word.capturedAt = Date()
        word.hesitationMs = hesitationMs
        word.isFromTest = isFromTest
        modelContext.insert(word)
        try modelContext.save()
    }

    public func hesitations(limit: Int = 200) throws -> [HesitationEntry] {
        var descriptor = FetchDescriptor<StoredWord>(
            sortBy: [SortDescriptor(\.hesitationMs, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        let words = try modelContext.fetch(descriptor)

        // Collapse repeats so the list shows habits rather than single incidents.
        let grouped = Dictionary(grouping: words, by: \.text)
        return grouped.map { text, entries in
            HesitationEntry(
                word: text,
                occurrences: entries.count,
                medianHesitationMs: entries
                    .map(\.hesitationMs)
                    .sorted()[entries.count / 2],
                isFromTest: entries.allSatisfy(\.isFromTest)
            )
        }
        .sorted { $0.medianHesitationMs > $1.medianHesitationMs }
    }

    /// Removes stored words older than the retention window.
    public func purgeExpiredWords(retentionDays: Int, now: Date = Date()) throws {
        let cutoff = now.addingTimeInterval(-Double(retentionDays) * 86_400)
        try modelContext.delete(
            model: StoredWord.self,
            where: #Predicate { $0.capturedAt < cutoff }
        )
        try modelContext.save()
    }

    public func deleteAllWords() throws {
        try modelContext.delete(model: StoredWord.self)
        try modelContext.save()
    }

    public func storedWordCount() throws -> Int {
        try modelContext.fetchCount(FetchDescriptor<StoredWord>())
    }

    public func storedWords(limit: Int = 500) throws -> [StoredWordEntry] {
        var descriptor = FetchDescriptor<StoredWord>(
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor).map {
            StoredWordEntry(text: $0.text, capturedAt: $0.capturedAt, isFromTest: $0.isFromTest)
        }
    }
}

public struct HesitationEntry: Sendable, Identifiable, Equatable {
    public var id: String { word }
    public let word: String
    public let occurrences: Int
    public let medianHesitationMs: Double
    public let isFromTest: Bool
}

public struct StoredWordEntry: Sendable, Identifiable, Equatable {
    public var id: String { "\(text)-\(capturedAt.timeIntervalSince1970)" }
    public let text: String
    public let capturedAt: Date
    public let isFromTest: Bool
}

public enum StoreFactory {
    public static let schema = Schema([StoredSession.self, StoredWord.self])

    public static func container(inMemory: Bool = false) throws -> ModelContainer {
        try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        )
    }
}

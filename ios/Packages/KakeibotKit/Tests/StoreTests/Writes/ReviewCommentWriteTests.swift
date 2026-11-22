import Core
import Foundation
import Store
import Testing

struct ReviewCommentWriteTests {
    @Test
    func savesAndOverwritesComment() async throws {
        let database = try AppDatabase.inMemory()
        let first = Self.comment(body: "食費が増えています。")
        let second = Self.comment(body: "交通費が減っています。")

        try await database.saveReviewComment(first)
        let saved = try await database.reviewComment(for: Self.period)
        try await database.saveReviewComment(second)
        let overwritten = try await database.reviewComment(for: Self.period)

        #expect(saved == first)
        #expect(overwritten == second)
    }

    @Test
    func returnsNilForOtherPeriod() async throws {
        let database = try AppDatabase.inMemory()

        try await database.saveReviewComment(Self.comment(body: "食費が増えています。"))
        let other = try await database.reviewComment(for: "month:2026-10-01")

        #expect(other == nil)
    }

    @Test
    func deletesCommentsWithRecords() async throws {
        let database = try AppDatabase.inMemory()

        try await database.saveReviewComment(Self.comment(body: "食費が増えています。"))
        try await database.deleteAllRecords(at: Self.now)
        let deleted = try await database.reviewComment(for: Self.period)

        #expect(deleted == nil)
    }

    @Test
    func deletesCommentsOnRestore() async throws {
        let database = try AppDatabase.inMemory()

        try database.insertDefaultsIfEmpty(at: Self.now)
        let tables = try database.snapshot()
        try await database.saveReviewComment(Self.comment(body: "食費が増えています。"))
        try database.replace(with: tables)
        let deleted = try await database.reviewComment(for: Self.period)

        #expect(deleted == nil)
    }
}

private extension ReviewCommentWriteTests {
    static let period = "month:2026-11-01"
    static let now = Date(timeIntervalSince1970: 1_794_000_000)

    static func comment(body: String) -> ReviewComment {
        ReviewComment(
            period: period,
            body: body,
            basis: "食費は予算の 97% を使っています。",
            createdAt: now
        )
    }
}

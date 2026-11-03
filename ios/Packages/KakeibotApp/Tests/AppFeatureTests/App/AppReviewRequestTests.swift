@testable import AppFeature
import Core
import Features
import Foundation
import Store
import Testing

struct AppReviewRequestTests {
    @Test
    func asksOnceWhenReady() async throws {
        let setup = try await Setup(entries: 30, daysAgo: 7)

        let first = await setup.request.shouldAsk(after: setup.recorded, at: setup.now)
        let saved = try await setup.database.setting(.reviewRequestedVersion)
        let second = await setup.request.shouldAsk(after: setup.recorded, at: setup.now)

        #expect(first)
        #expect(saved == "1.2")
        #expect(!second)
    }

    @Test
    func asksAgainForNewVersion() async throws {
        let setup = try await Setup(entries: 30, daysAgo: 7)
        let next = AppReviewRequest(
            database: setup.database,
            version: "1.3",
            calendar: Setup.calendar
        )

        _ = await setup.request.shouldAsk(after: setup.recorded, at: setup.now)
        let asked = await next.shouldAsk(after: setup.recorded, at: setup.now)

        #expect(asked)
    }

    @Test
    func waitsForThirtyEntries() async throws {
        let setup = try await Setup(entries: 29, daysAgo: 7)

        let asked = await setup.request.shouldAsk(after: setup.recorded, at: setup.now)
        let saved = try await setup.database.setting(.reviewRequestedVersion)

        #expect(!asked)
        #expect(saved == nil)
    }

    @Test
    func waitsForSevenDays() async throws {
        let setup = try await Setup(entries: 30, daysAgo: 6)

        let asked = await setup.request.shouldAsk(after: setup.recorded, at: setup.now)

        #expect(!asked)
    }

    @Test
    func skipsEditsAndDeletes() async throws {
        let setup = try await Setup(entries: 30, daysAgo: 7)
        let entry = setup.recorded.entry
        let edited = EntryChange(
            kind: .edited(previous: entry, previousFee: nil),
            entry: entry,
            label: "食費"
        )
        let deleted = EntryChange(kind: .deleted, entry: entry, label: "食費")

        let askedEdit = await setup.request.shouldAsk(after: edited, at: setup.now)
        let askedDelete = await setup.request.shouldAsk(after: deleted, at: setup.now)
        let saved = try await setup.database.setting(.reviewRequestedVersion)

        #expect(!askedEdit)
        #expect(!askedDelete)
        #expect(saved == nil)
    }

    @Test
    func skipsWithoutEntries() async throws {
        let setup = try await Setup(entries: 0, daysAgo: 7)

        let asked = await setup.request.shouldAsk(after: setup.recorded, at: setup.now)

        #expect(!asked)
    }
}

extension AppReviewRequestTests {
    struct Setup {
        static var calendar: Calendar {
            var calendar = Calendar(identifier: .gregorian)

            calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt

            return calendar
        }

        let database: AppDatabase
        let request: AppReviewRequest
        let recorded: EntryChange
        let now: Date
    }
}

extension AppReviewRequestTests.Setup {
    init(
        entries: Int,
        daysAgo: Int
    ) async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        let first = now.addingTimeInterval(TimeInterval(-daysAgo * 86400))
        try database.insertDefaultsIfEmpty(at: first)
        let options = try await database.entryOptions()
        let date = try #require(LocalDate("2026-10-03"))

        let draft = EntryDraft(
            type: .expense,
            amount: 980,
            date: date,
            categoryId: options.expenseCategories[0].id,
            walletId: options.wallets[0].id
        )

        for index in 0..<entries {
            try await database.saveEntry(draft, at: index == 0 ? first : now)
        }

        let entry = Entry(
            type: .expense,
            amount: 980,
            date: date,
            categoryId: options.expenseCategories[0].id,
            walletId: options.wallets[0].id,
            createdAt: now,
            updatedAt: now
        )

        self.init(
            database: database,
            request: AppReviewRequest(
                database: database,
                version: "1.2",
                calendar: Self.calendar
            ),
            recorded: EntryChange(kind: .recorded, entry: entry, label: "食費"),
            now: now
        )
    }
}

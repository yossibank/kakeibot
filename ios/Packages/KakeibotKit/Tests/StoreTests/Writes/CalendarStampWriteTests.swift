import Core
import Foundation
import Store
import Testing

struct CalendarStampWriteTests {
    @Test
    func stampsAndReplacesOnTheSameDay() async throws {
        let setup = try await Setup()
        let star = try #require(setup.shelf.first)
        let party = try #require(setup.shelf.dropFirst().first)

        try await setup.database.stamp(star, on: setup.day, at: setup.now)
        let first = try await setup.database.stampCalendar()

        try await setup.database.stamp(party, on: setup.day, at: setup.now)
        let replaced = try await setup.database.stampCalendar()

        #expect(first.stamps.count == 1)
        #expect(first.icon(on: setup.day)?.glyph == .star)
        #expect(replaced.stamps.count == 1)
        #expect(replaced.icon(on: setup.day)?.glyph == .party)
    }

    @Test
    func removesStamp() async throws {
        let setup = try await Setup()
        let star = try #require(setup.shelf.first)
        let nextDay = setup.day.adding(days: 1)
        try await setup.database.stamp(star, on: setup.day, at: setup.now)
        try await setup.database.stamp(star, on: nextDay, at: setup.now)

        try await setup.database.removeStamp(on: setup.day)
        let calendar = try await setup.database.stampCalendar()

        #expect(calendar.stamps[setup.day] == nil)
        #expect(calendar.icon(on: nextDay)?.glyph == .star)
    }

    @Test
    func keepsStampWhenItsStampIsHidden() async throws {
        let setup = try await Setup()
        let shelf = try await setup.database.iconShelf()
        let first = try #require(shelf.shelfIcons.first)
        try await setup.database.stamp(
            first.iconId,
            on: setup.day,
            at: setup.now
        )

        try await setup.database.setShelfIconHidden(
            first.id,
            isHidden: true,
            at: setup.now
        )
        let calendar = try await setup.database.stampCalendar()

        #expect(calendar.icon(on: setup.day)?.glyph == .star)
    }

    @Test
    func talliesStampsInRange() async throws {
        let setup = try await Setup()
        let star = try #require(setup.shelf.first)
        let party = try #require(setup.shelf.dropFirst().first)
        let cake = try #require(setup.shelf.dropFirst(3).first)
        let start = setup.day
        let end = start.adding(days: 6)
        let stamps = [
            (star, start),
            (party, start.adding(days: 1)),
            (star, start.adding(days: 2)),
            (cake, start.adding(days: 3)),
            (star, end.adding(days: 1))
        ]

        for (icon, date) in stamps {
            try await setup.database.stamp(icon, on: date, at: setup.now)
        }

        let calendar = try await setup.database.stampCalendar()
        let tallies = calendar.tallies(in: start...end)

        #expect(tallies.map(\.icon.glyph) == [.star, .cake, .party])
        #expect(tallies.map(\.count) == [2, 1, 1])
    }
}

extension CalendarStampWriteTests {
    struct Setup {
        let database: AppDatabase
        let now: Date
        let day: LocalDate
        let shelf: [Icon.ID]
    }
}

extension CalendarStampWriteTests.Setup {
    init() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        let day = try #require(LocalDate("2026-10-19"))
        try database.insertShelfIfEmpty(at: now)
        let shelf = try await database.iconShelf().shelfIcons.map(\.iconId)
        self.init(database: database, now: now, day: day, shelf: shelf)
    }
}

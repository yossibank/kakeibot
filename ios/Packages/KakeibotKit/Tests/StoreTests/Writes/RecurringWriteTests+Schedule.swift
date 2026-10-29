import Core
import Foundation
import Store
import Testing

extension RecurringWriteTests {
    @Test
    func generatesOnShiftedDate() async throws {
        let setup = try await Setup()
        let today = try #require(LocalDate("2026-04-30"))
        try await setup.shiftHoliday(to: .next)

        try await setup.database.generateRecurringEntries(through: today, at: setup.now)
        let entries = try setup.database.snapshot().entries
        let dates = entries.map(\.date).sorted().map(\.description)
        let scheduled = entries.compactMap(\.recurringDate).sorted().map(\.description)

        #expect(dates == [
            "2026-01-26",
            "2026-02-25",
            "2026-03-25",
            "2026-04-27"
        ])
        #expect(scheduled == [
            "2026-01-25",
            "2026-02-25",
            "2026-03-25",
            "2026-04-25"
        ])
    }

    @Test
    func keepsOneEntryAfterChangingShift() async throws {
        let setup = try await Setup()
        let saturday = try #require(LocalDate("2026-04-25"))
        let may = try #require(LocalDate("2026-05-31"))
        try await setup.database.generateRecurringEntries(through: saturday, at: setup.now)
        try await setup.shiftHoliday(to: .next)

        try await setup.database.generateRecurringEntries(through: may, at: setup.now)

        let dates = try setup.database
            .snapshot()
            .entries
            .compactMap(\.recurringDate)
            .sorted()
            .map(\.description)

        #expect(dates == [
            "2026-01-25",
            "2026-02-25",
            "2026-03-25",
            "2026-04-25",
            "2026-05-25"
        ])
    }

    @Test(arguments: [20, 12])
    func keepsOneEntryAfterChangingDay(day: Int) async throws {
        let setup = try await Setup()
        let first = try #require(LocalDate("2026-03-10"))
        let last = try #require(LocalDate("2026-03-31"))
        try await setup.database.generateRecurringEntries(through: first, at: setup.now)
        try await setup.changeDay(to: day)

        try await setup.database.generateRecurringEntries(through: last, at: setup.now)

        let dates = try setup.database
            .snapshot()
            .entries
            .compactMap(\.recurringDate)
            .sorted()
            .map(\.description)

        #expect(dates == ["2026-01-25", "2026-02-25", "2026-03-\(day)"])
    }

    @Test
    func generatesPastEntriesWhenStartMovesEarlier() async throws {
        let setup = try await Setup()
        let today = try #require(LocalDate("2026-03-31"))
        let earlier = try #require(LocalDate("2025-11-01"))
        try await setup.database.generateRecurringEntries(through: today, at: setup.now)
        let recurring = try #require(setup.database.snapshot().recurrings.first)
        var draft = RecurringDraft(recurring)
        draft.startDate = earlier

        _ = try await setup.database.saveRecurring(
            draft,
            editing: recurring.id,
            today: today,
            at: setup.now
        )

        let dates = try setup.database
            .snapshot()
            .entries
            .compactMap(\.recurringDate)
            .sorted()
            .map(\.description)

        #expect(dates == [
            "2025-11-25",
            "2025-12-25",
            "2026-01-25",
            "2026-02-25",
            "2026-03-25"
        ])
    }

    @Test
    func createsNextOccurrenceAfterDroppingShift() async throws {
        let setup = try await Setup()
        let paid = try #require(LocalDate("2027-03-01"))
        let end = try #require(LocalDate("2027-03-31"))
        try await setup.change(day: 27, shift: .next)
        try await setup.database.generateRecurringEntries(through: paid, at: setup.now)
        try await setup.change(day: 27, shift: .none)

        try await setup.database.generateRecurringEntries(through: end, at: setup.now)

        let scheduled = try setup.database
            .snapshot()
            .entries
            .compactMap(\.recurringDate)
            .filter { $0.description >= "2027-02-01" }
            .sorted()
            .map(\.description)

        #expect(scheduled == ["2027-02-27", "2027-03-27"])
    }

    @Test
    func createsNextOccurrenceAfterChangingDay() async throws {
        let setup = try await Setup()
        let paid = try #require(LocalDate("2027-03-01"))
        let end = try #require(LocalDate("2027-03-31"))
        try await setup.change(day: 27, shift: .next)
        try await setup.database.generateRecurringEntries(through: paid, at: setup.now)
        try await setup.change(day: 20, shift: .next)

        try await setup.database.generateRecurringEntries(through: end, at: setup.now)

        let scheduled = try setup.database
            .snapshot()
            .entries
            .compactMap(\.recurringDate)
            .filter { $0.description >= "2027-02-01" }
            .sorted()
            .map(\.description)

        #expect(scheduled == ["2027-02-27", "2027-03-20"])
    }

    @Test
    func createsNextOccurrenceAfterYearEndShift() async throws {
        let setup = try await Setup()
        let shifted = try #require(LocalDate("2027-01-04"))
        let end = try #require(LocalDate("2027-01-31"))
        try await setup.change(day: 31, shift: .next)
        try await setup.database.generateRecurringEntries(through: shifted, at: setup.now)
        try await setup.change(day: 31, shift: .none)

        try await setup.database.generateRecurringEntries(through: end, at: setup.now)

        let scheduled = try setup.database
            .snapshot()
            .entries
            .compactMap(\.recurringDate)
            .filter { $0.description >= "2026-12-01" }
            .sorted()
            .map(\.description)

        #expect(scheduled == ["2026-12-31", "2027-01-31"])
    }

    @Test
    func keepsDeletedOccurrenceWhenStartMovesEarlier() async throws {
        let setup = try await Setup()
        let today = try #require(LocalDate("2026-03-31"))
        let earlier = try #require(LocalDate("2025-11-01"))
        try await setup.database.generateRecurringEntries(through: today, at: setup.now)

        try await setup.database.writer.write { db in
            try db.execute(sql: "DELETE FROM entry WHERE recurring_date = '2026-02-25'")
        }

        let recurring = try #require(setup.database.snapshot().recurrings.first)
        var draft = RecurringDraft(recurring)
        draft.startDate = earlier
        draft.day = 20

        _ = try await setup.database.saveRecurring(
            draft,
            editing: recurring.id,
            today: today,
            at: setup.now
        )

        let dates = try setup.database
            .snapshot()
            .entries
            .compactMap(\.recurringDate)
            .sorted()
            .map(\.description)

        #expect(dates == [
            "2025-11-20",
            "2025-12-20",
            "2026-01-25",
            "2026-03-25"
        ])
    }

    @Test
    func pausesWhileHiddenWithoutBackfill() async throws {
        let setup = try await Setup()
        let january = try #require(LocalDate("2026-01-31"))
        let february = try #require(LocalDate("2026-02-01"))
        let april = try #require(LocalDate("2026-04-30"))
        let may = try #require(LocalDate("2026-05-25"))
        try await setup.database.generateRecurringEntries(through: january, at: setup.now)
        let recurring = try #require(try setup.database.snapshot().recurrings.first)

        try await setup.database.setRecurringHidden(
            recurring.id,
            isHidden: true,
            today: february,
            at: setup.now
        )

        try await setup.database.generateRecurringEntries(through: april, at: setup.now)
        let shownWhileHidden = try await setup.database.recurrings()
        let allWhileHidden = try await setup.database.recurrings(includingHidden: true)

        try await setup.database.setRecurringHidden(
            recurring.id,
            isHidden: false,
            today: may,
            at: setup.now
        )

        let dates = try setup.database
            .snapshot()
            .entries
            .compactMap(\.recurringDate)
            .sorted()
            .map(\.description)

        #expect(shownWhileHidden.isEmpty)
        #expect(allWhileHidden.count == 1)
        #expect(dates == ["2026-01-25", "2026-05-25"])
    }
}

private extension RecurringWriteTests.Setup {
    func changeDay(to day: Int) async throws {
        try await database.writer.write { db in
            for var recurring in try Recurring.fetchAll(db) {
                recurring.day = day
                recurring.generatedUntil = nil
                try recurring.update(db)
            }
        }
    }

    func change(
        day: Int,
        shift: Recurring.HolidayShift
    ) async throws {
        try await database.writer.write { db in
            for var recurring in try Recurring.fetchAll(db) {
                recurring.day = day
                recurring.holidayShift = shift
                try recurring.update(db)
            }
        }
    }

    func shiftHoliday(to shift: Recurring.HolidayShift) async throws {
        try await database.writer.write { db in
            for var recurring in try Recurring.fetchAll(db) {
                recurring.holidayShift = shift
                try recurring.update(db)
            }
        }
    }
}

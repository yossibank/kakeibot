import Core
import Foundation
import Store
import Testing

struct NotificationInputTests {
    @Test
    func collectsRecordedDatesFromStart() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        try database.insertDefaultsIfEmpty(at: now)
        let options = try await database.entryOptions()
        let before = try #require(LocalDate("2026-10-16"))
        let today = try #require(LocalDate("2026-10-17"))
        let marked = try #require(LocalDate("2026-10-18"))
        let time = try #require(ReminderTime("21:00"))

        for date in [before, today, today] {
            let draft = EntryDraft(
                type: .expense,
                amount: 500,
                date: date,
                categoryId: options.expenseCategories[0].id,
                walletId: options.wallets[0].id
            )

            try await database.saveEntry(draft, at: now)
        }

        try await database.markNoSpendDay(marked, at: now)
        try await database.setSetting(.reminderTime, to: time)
        let input = try await database.notificationInput(from: today)
        let food = options.expenseCategories[0]

        #expect(input.recordedDates == [today, marked])
        #expect(input.reminderTime == time)
        #expect(input.names[food.id] == food.name)
        #expect(input.recurrings.isEmpty)
    }

    @Test
    func publishesSameInputAsOneRead() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        try database.insertDefaultsIfEmpty(at: now)
        let options = try await database.entryOptions()
        let bill = try await database.insertCardBill(at: now)
        let card = try #require(bill.toWalletId)
        let used = try #require(LocalDate("2026-10-10"))
        let today = try #require(LocalDate("2026-10-17"))
        let marked = try #require(LocalDate("2026-10-18"))
        let time = try #require(ReminderTime("21:00"))

        let spending = EntryDraft(
            type: .expense,
            amount: 5000,
            date: used,
            categoryId: options.expenseCategories[0].id,
            walletId: card
        )

        let lunch = EntryDraft(
            type: .expense,
            amount: 800,
            date: today,
            categoryId: options.expenseCategories[0].id,
            walletId: options.wallets[0].id
        )

        try await database.saveEntry(spending, at: now)
        try await database.markNoSpendDay(marked, at: now)
        try await database.setSetting(.reminderTime, to: time)

        var updates = database.notificationInputUpdates(from: today).makeAsyncIterator()
        let first = try await updates.next()
        let read = try await database.notificationInput(from: today)

        #expect(first == read)
        #expect(read.recordedDates == [marked])
        #expect(read.shortages.map(\.amount) == [5000])

        try await database.saveEntry(lunch, at: now)
        let next = try await updates.next()
        let reread = try await database.notificationInput(from: today)

        #expect(next == reread)
        #expect(next?.recordedDates == [today, marked])
    }
}

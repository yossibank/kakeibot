import Core
import Foundation
import Store
import Testing

struct CardBillRecalcWriteTests {
    @Test
    func raisesAndRestoresBillWhenUsageChanges() async throws {
        let setup = try await Setup(usage: [10000])

        let added = try await setup.spend(3000, on: "2026-10-05")
        #expect(try setup.bill()?.amount == 13000)

        try await setup.database.deleteEntry(added.id)
        #expect(try setup.bill()?.amount == 10000)
    }

    @Test
    func removesBillWhenUsageBecomesZero() async throws {
        let setup = try await Setup(usage: [10000])
        let entry = try #require(try setup.database.snapshot().entries
            .first { $0.recurringId == nil })

        try await setup.database.deleteEntry(entry.id)

        #expect(try setup.bill() == nil)
        #expect(try setup.database.snapshot().entries.isEmpty)
    }

    @Test
    func createsBillSkippedAsZero() async throws {
        let setup = try await Setup(usage: [])
        #expect(try setup.bill() == nil)

        try await setup.spend(4000, on: "2026-10-05")

        let bill = try setup.bill()
        #expect(bill?.amount == 4000)
        #expect(bill?.date == LocalDate("2026-11-10"))
    }

    @Test
    func keepsBillEditedByHand() async throws {
        let setup = try await Setup(usage: [10000])
        let bill = try #require(try setup.bill())

        try await setup.database.writer.write { db in
            var edited = bill
            edited.amount = 777
            edited.updatedAt = bill.updatedAt.addingTimeInterval(60)
            try edited.update(db)
        }

        try await setup.spend(3000, on: "2026-10-05")

        #expect(try setup.bill()?.amount == 777)
    }

    @Test
    func ignoresUsageOutsidePeriodAndOtherWallets() async throws {
        let setup = try await Setup(usage: [10000])

        try await setup.spend(3000, on: "2026-10-16")
        try await setup.spend(3000, on: "2026-09-15")
        try await setup.spend(3000, on: "2026-10-05", wallet: setup.bank)

        let bill = try setup.bill()
        #expect(bill?.amount == 10000)
        #expect(bill?.updatedAt == bill?.createdAt)
    }

    @Test
    func recalculatesWhenEntryMovesAcrossPeriods() async throws {
        let setup = try await Setup(usage: [10000])
        let entry = try await setup.spend(3000, on: "2026-10-05")
        #expect(try setup.bill()?.amount == 13000)

        var draft = EntryDraft(entry)
        draft.date = try #require(LocalDate("2026-10-20"))

        try await setup.database.saveEntry(
            draft,
            editing: entry.id,
            at: setup.now.addingTimeInterval(1)
        )

        #expect(try setup.bill()?.amount == 10000)
    }

    @Test
    func recalculatesWhenDeletionIsRestored() async throws {
        let setup = try await Setup(usage: [10000])
        let entry = try await setup.spend(3000, on: "2026-10-05")

        try await setup.database.deleteEntry(entry.id)
        #expect(try setup.bill()?.amount == 10000)

        try await setup.database.restoreEntry(entry)
        #expect(try setup.bill()?.amount == 13000)
    }

    @Test
    func recalculatesForWidgetEntryAndUndo() async throws {
        let setup = try await Setup(usage: [10000])

        let draft = EntryTemplateDraft(
            name: "カード",
            type: .expense,
            amount: 2000,
            categoryId: setup.category,
            walletId: setup.card
        )

        let template = try await setup.database.saveTemplate(draft, at: setup.now)
        let date = try #require(LocalDate("2026-10-05"))

        let entry = try await setup.database.recordFromWidget(
            template.id,
            on: date,
            at: setup.now
        )

        #expect(try setup.bill()?.amount == 12000)

        try await setup.database.undoWidgetEntry(entry.id)
        #expect(try setup.bill()?.amount == 10000)
    }
}

extension CardBillRecalcWriteTests {
    struct Setup {
        let database: AppDatabase
        let now: Date
        let bank: Wallet.ID
        let card: Wallet.ID
        let category: EntryCategory.ID
        let recurringId: Recurring.ID
    }
}

extension CardBillRecalcWriteTests.Setup {
    init(usage: [Int]) async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        try database.insertDefaultsIfEmpty(at: now)
        let options = try await database.entryOptions()
        let bank = options.wallets[0].id
        let card = options.wallets[1].id
        let category = options.expenseCategories[0].id

        let bill = try Recurring(
            type: .transfer,
            amount: 0,
            categoryId: nil,
            walletId: bank,
            toWalletId: card,
            frequency: .monthly,
            day: 10,
            closingDay: 15,
            startDate: #require(LocalDate("2026-11-01")),
            createdAt: now,
            updatedAt: now
        )

        try await database.writer.write { db in
            try bill.insert(db)
        }

        self.init(
            database: database,
            now: now,
            bank: bank,
            card: card,
            category: category,
            recurringId: bill.id
        )

        for amount in usage {
            try await spend(amount, on: "2026-10-01")
        }

        try await database.generateRecurringEntries(
            through: #require(LocalDate("2026-11-10")),
            at: now
        )
    }
}

extension CardBillRecalcWriteTests.Setup {
    @discardableResult
    func spend(
        _ amount: Int,
        on date: String,
        wallet: Wallet.ID? = nil
    ) async throws -> Entry {
        let draft = try EntryDraft(
            type: .expense,
            amount: amount,
            date: #require(LocalDate(date)),
            categoryId: category,
            walletId: wallet ?? card
        )

        return try await database.saveEntry(draft, at: now)
    }

    func bill() throws -> Entry? {
        try database.snapshot().entries.first { $0.recurringId == recurringId }
    }
}

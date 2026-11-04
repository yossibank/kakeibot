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
        let usage = try setup.database.snapshot().entries.first { $0.recurringId == nil }
        let entry = try #require(usage)

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

        let later = setup.now.addingTimeInterval(1)
        var draft = EntryDraft(entry)
        draft.date = try #require(LocalDate("2026-10-20"))

        try await setup.database.saveEntry(draft, editing: entry.id, at: later)

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

        let entry = try await setup.database.recordFromWidget(template.id, on: date, at: setup.now)
        #expect(try setup.bill()?.amount == 12000)

        try await setup.database.undoWidgetEntry(entry.id)
        #expect(try setup.bill()?.amount == 10000)
    }

    @Test
    func restoresOneBillAfterBulkDeleteOfUsageAndBill() async throws {
        let setup = try await Setup(usage: [10000])
        let added = try await setup.spend(3000, on: "2026-10-05")
        let bill = try #require(try setup.bill())

        let deleted = try await setup.database.deleteEntries([added.id, bill.id])
        #expect(try setup.bills().isEmpty)

        try await setup.database.restoreEntries(deleted)
        let bills = try setup.bills()

        #expect(bills.count == 1)
        #expect(bills.first?.amount == 13000)
    }

    @Test
    func doesNotRecreateBillDeletedByHand() async throws {
        let setup = try await Setup(usage: [10000])
        let bill = try #require(try setup.bill())
        let added = try await setup.spend(3000, on: "2026-10-05")
        let later = setup.now.addingTimeInterval(1)

        try await setup.database.deleteEntry(bill.id)

        var draft = EntryDraft(added)
        draft.amount = 5000

        try await setup.database.saveEntry(draft, editing: added.id, at: later)

        #expect(try setup.bills().isEmpty)
    }

    @Test
    func restoresBillRemovedWithAllUsage() async throws {
        let setup = try await Setup(usage: [10000])
        let found = try setup.database.snapshot().entries.first { $0.recurringId == nil }
        let usage = try #require(found)

        let deleted = try await setup.database.deleteEntries([usage.id])
        #expect(try setup.bills().isEmpty)

        try await setup.database.restoreEntries(deleted)
        let bills = try setup.bills()

        #expect(bills.count == 1)
        #expect(bills.first?.amount == 10000)
    }

    @Test
    func restoresBillOfPreviousWalletOnUndo() async throws {
        let setup = try await Setup(usage: [10000])
        let startDate = try #require(LocalDate("2026-11-01"))
        let through = try #require(LocalDate("2026-11-10"))
        let later = setup.now.addingTimeInterval(1)

        let other = Recurring(
            type: .transfer,
            amount: 0,
            categoryId: nil,
            walletId: setup.card,
            toWalletId: setup.bank,
            frequency: .monthly,
            day: 10,
            closingDay: 15,
            startDate: startDate,
            createdAt: setup.now,
            updatedAt: setup.now
        )

        try await setup.database.writer.write { db in
            try other.insert(db)
        }

        try await setup.database.generateRecurringEntries(through: through, at: setup.now)
        let found = try setup.database.snapshot().entries.first { $0.recurringId == nil }
        let usage = try #require(found)

        let previous = try await setup.database.changeEntries(
            [usage.id],
            to: .wallet(setup.bank),
            at: later
        )

        #expect(try setup.bill() == nil)
        #expect(try setup.bill(of: other.id)?.amount == 10000)

        try await setup.database.restoreEntries(previous)

        #expect(try setup.bill()?.amount == 10000)
        #expect(try setup.bill(of: other.id) == nil)
    }

    @Test
    func countsGeneratedTransferAndFeeInBill() async throws {
        let setup = try await Setup(usage: [])
        let startDate = try #require(LocalDate("2026-10-05"))
        let through = try #require(LocalDate("2026-11-10"))

        let transfer = Recurring(
            type: .transfer,
            amount: 5000,
            categoryId: nil,
            walletId: setup.card,
            toWalletId: setup.bank,
            frequency: .monthly,
            day: 5,
            fee: 110,
            startDate: startDate,
            createdAt: setup.now,
            updatedAt: setup.now
        )

        try await setup.database.writer.write { db in
            try transfer.insert(db)
        }

        try await setup.database.generateRecurringEntries(through: through, at: setup.now)

        #expect(try setup.bill()?.amount == 5110)
    }

    @Test
    func keepsBillWhenDeletedRecurringIsRestored() async throws {
        let setup = try await Setup(usage: [10000])
        let startDate = try #require(LocalDate("2026-10-01"))
        let through = try #require(LocalDate("2026-11-10"))

        let expense = Recurring(
            type: .expense,
            amount: 2000,
            categoryId: setup.category,
            walletId: setup.card,
            frequency: .monthly,
            day: 1,
            startDate: startDate,
            createdAt: setup.now,
            updatedAt: setup.now
        )

        try await setup.database.writer.write { db in
            try expense.insert(db)
        }

        try await setup.database.generateRecurringEntries(through: through, at: setup.now)
        #expect(try setup.bill()?.amount == 12000)

        let deletion = try await setup.database.deleteRecurring(expense.id, at: setup.now)

        try await setup.database.writer.write { db in
            let stored = try Recurring.fetchOne(db, key: setup.recurringId)

            var bill = try #require(stored)

            bill.closingDay = 1

            try bill.update(db)
        }

        try await setup.database.restore(deletion)

        #expect(try setup.bill()?.amount == 12000)
    }

    @Test
    func replacesBillRecordedOnAnotherDayOfSameMonth() async throws {
        let setup = try await Setup(usage: [10000])
        let bill = try #require(try setup.bill())
        let movedDate = try #require(LocalDate("2026-11-12"))

        try await setup.database.deleteEntry(bill.id)

        let moved = Entry(
            type: .transfer,
            amount: 999,
            date: movedDate,
            categoryId: nil,
            walletId: setup.bank,
            toWalletId: setup.card,
            recurringId: setup.recurringId,
            recurringDate: movedDate,
            createdAt: setup.now,
            updatedAt: setup.now
        )

        try await setup.database.restoreEntries([moved])
        try await setup.database.restoreEntries([bill])
        let bills = try setup.bills()

        #expect(bills.count == 1)
        #expect(bills.first?.id == bill.id)
    }

    @Test
    func recalculatesBillOfCardPayingAnotherCard() async throws {
        let setup = try await Setup(usage: [])
        let startDate = try #require(LocalDate("2026-11-01"))
        let through = try #require(LocalDate("2026-11-30"))

        let draft = WalletDraft(
            kind: .card,
            name: "払う側のカード",
            mark: .glyph(.bank),
            color: "#4A6FA5",
            initialBalance: 0
        )

        let payer = try await setup.database.saveWallet(draft, at: setup.now)

        let payerBill = Recurring(
            type: .transfer,
            amount: 0,
            categoryId: nil,
            walletId: setup.bank,
            toWalletId: payer.id,
            frequency: .monthly,
            day: 25,
            closingDay: 10,
            startDate: startDate,
            createdAt: setup.now,
            updatedAt: setup.now
        )

        try await setup.database.writer.write { db in
            var bill = try #require(try Recurring.fetchOne(db, key: setup.recurringId))

            bill.walletId = payer.id

            try bill.update(db)
            try payerBill.insert(db)
        }

        try await setup.spend(10000, on: "2026-10-01")
        try await setup.database.generateRecurringEntries(through: through, at: setup.now)
        #expect(try setup.bill()?.amount == 10000)
        #expect(try setup.bill(of: payerBill.id)?.amount == 10000)

        try await setup.spend(3000, on: "2026-10-05")
        #expect(try setup.bill()?.amount == 13000)
        #expect(try setup.bill(of: payerBill.id)?.amount == 13000)
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

import Core
import Foundation
import Store
import Testing

struct TransferFeeWriteTests {
    @Test
    func savesFeeAsExpenseOfSourceWallet() async throws {
        let setup = try await Setup()

        let transfer = try await setup.database.saveEntry(setup.draft, at: setup.now)

        let fee = try #require(try await setup.database.fee(of: transfer.id))
        let options = try await setup.database.entryOptions()
        let category = options.expenseCategories.first { $0.id == fee.categoryId }

        #expect(fee.type == .expense)
        #expect(fee.amount == 110)
        #expect(fee.date == transfer.date)
        #expect(fee.walletId == transfer.walletId)
        #expect(fee.transferId == transfer.id)
        #expect(category?.name == "手数料")
    }

    @Test
    func reusesFeeCategory() async throws {
        let setup = try await Setup()

        let first = try await setup.database.saveEntry(setup.draft, at: setup.now)
        let second = try await setup.database.saveEntry(setup.draft, at: setup.now)

        let firstFee = try await setup.database.fee(of: first.id)
        let secondFee = try await setup.database.fee(of: second.id)
        let options = try await setup.database.entryOptions()
        let names = options.expenseCategories.map(\.name).filter { $0 == "手数料" }

        #expect(firstFee?.categoryId == secondFee?.categoryId)
        #expect(names.count == 1)
    }

    @Test
    func followsEditedTransfer() async throws {
        let setup = try await Setup()
        let date = try #require(LocalDate("2026-10-05"))
        var edited = setup.draft
        edited.fee = 220
        edited.date = date

        let transfer = try await setup.database.saveEntry(setup.draft, at: setup.now)
        let before = try await setup.database.fee(of: transfer.id)

        try await setup.database.saveEntry(
            edited,
            editing: transfer.id,
            at: setup.now
        )

        let after = try await setup.database.fee(of: transfer.id)

        #expect(after?.id == before?.id)
        #expect(after?.amount == 220)
        #expect(after?.date == date)
    }

    @Test
    func removesFeeWhenCleared() async throws {
        let setup = try await Setup()
        var edited = setup.draft
        edited.fee = 0

        let transfer = try await setup.database.saveEntry(setup.draft, at: setup.now)

        try await setup.database.saveEntry(
            edited,
            editing: transfer.id,
            at: setup.now
        )

        let snapshot = try setup.database.snapshot()

        #expect(snapshot.entries.map(\.id) == [transfer.id])
    }

    @Test
    func keepsFeeWalletOnBatchChange() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()

        let transfer = try await setup.database.saveEntry(setup.draft, at: setup.now)
        let fee = try #require(try await setup.database.fee(of: transfer.id))

        let changed = try await setup.database.changeEntries(
            [fee.id],
            to: .wallet(options.wallets[0].id),
            at: setup.now
        )

        let after = try await setup.database.fee(of: transfer.id)

        #expect(changed.isEmpty)
        #expect(after?.walletId == transfer.walletId)
    }

    @Test
    func deletesFeeWithTransfer() async throws {
        let setup = try await Setup()

        let transfer = try await setup.database.saveEntry(setup.draft, at: setup.now)

        try await setup.database.deleteEntry(transfer.id)

        let snapshot = try setup.database.snapshot()

        #expect(snapshot.entries.isEmpty)
    }

    @Test
    func restoresDeletedTransferWithFee() async throws {
        let setup = try await Setup()

        let transfer = try await setup.database.saveEntry(setup.draft, at: setup.now)
        let fee = try await setup.database.fee(of: transfer.id)

        try await setup.database.deleteEntry(transfer.id)
        try await setup.database.restoreEntry(transfer, fee: fee)

        let snapshot = try setup.database.snapshot()

        #expect(Set(snapshot.entries) == Set([transfer, fee].compactMap(\.self)))
    }

    @Test
    func restoringTransferWithoutFeeRemovesAddedFee() async throws {
        let setup = try await Setup()
        var draft = setup.draft
        draft.fee = 0

        let transfer = try await setup.database.saveEntry(draft, at: setup.now)

        try await setup.database.saveEntry(
            setup.draft,
            editing: transfer.id,
            at: setup.now
        )

        try await setup.database.restoreEntry(transfer, fee: nil)

        let snapshot = try setup.database.snapshot()

        #expect(snapshot.entries == [transfer])
    }

    @Test
    func deletesAndRestoresEntriesWithFees() async throws {
        let setup = try await Setup()

        let transfer = try await setup.database.saveEntry(setup.draft, at: setup.now)
        let fee = try await setup.database.fee(of: transfer.id)

        let deleted = try await setup.database.deleteEntries([transfer.id])

        try await setup.database.restoreEntries(deleted.reversed())

        let snapshot = try setup.database.snapshot()

        #expect(Set(deleted) == Set([transfer, fee].compactMap(\.self)))
        #expect(Set(snapshot.entries) == Set(deleted))
    }

    @Test
    func replacesTablesWithFeeBeforeTransfer() async throws {
        let setup = try await Setup()

        try await setup.database.saveEntry(setup.draft, at: setup.now)

        var tables = try setup.database.snapshot()
        tables.entries.reverse()

        try setup.database.replace(with: tables)

        let snapshot = try setup.database.snapshot()

        #expect(Set(snapshot.entries) == Set(tables.entries))
    }
}

extension TransferFeeWriteTests {
    struct Setup {
        let database: AppDatabase
        let now: Date
        let draft: EntryDraft
    }
}

extension TransferFeeWriteTests.Setup {
    init() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        try database.insertDefaultsIfEmpty(at: now)
        let options = try await database.entryOptions()
        let date = try #require(LocalDate("2026-10-03"))

        let draft = EntryDraft(
            type: .transfer,
            amount: 10000,
            date: date,
            categoryId: nil,
            walletId: options.wallets[1].id,
            toWalletId: options.wallets[0].id,
            fee: 110
        )

        self.init(
            database: database,
            now: now,
            draft: draft
        )
    }
}

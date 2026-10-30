import Core
import Foundation
import Store
import Testing

struct DeletionSubjectTests {
    @Test
    func namesDeletedWallet() async throws {
        let setup = try await WalletWriteTests.Setup()
        let card = try await setup.database.saveWallet(setup.draft, at: setup.now)

        let deletion = try await setup.database.deleteWallet(card.id, at: setup.now)

        #expect(deletion.subject?.kind == .wallet)
        #expect(deletion.subject?.count == 1)
        #expect(deletion.subject?.names == ["楽天カード"])
    }

    @Test
    func namesRecurringByMemoOnly() async throws {
        let setup = try await WalletWriteTests.Setup()
        let options = try await setup.database.entryOptions()
        let category = options.expenseCategories[0].id
        let bank = try await setup.wallet(named: "銀行")
        let day = try #require(LocalDate("2026-11-01"))
        let rentDraft = Self.draft(memo: "家賃", categoryId: category, walletId: bank.id, on: day)
        let otherDraft = Self.draft(memo: "", categoryId: category, walletId: bank.id, on: day)
        let rent = try await setup.database.saveRecurring(rentDraft, today: day, at: setup.now)
        let other = try await setup.database.saveRecurring(otherDraft, today: day, at: setup.now)

        let named = try await setup.database.deleteRecurring(rent.id, at: setup.now)
        let unnamed = try await setup.database.deleteRecurring(other.id, at: setup.now)

        #expect(named.subject?.kind == .recurring)
        #expect(named.subject?.names == ["家賃"])
        #expect(unnamed.subject?.count == 1)
        #expect(unnamed.subject?.names.isEmpty == true)
    }

    @Test
    func countsMergedDeletions() async throws {
        let setup = try await WalletWriteTests.Setup()
        let first = try await setup.database.saveWallet(setup.draft, at: setup.now)
        let second = try await setup.database.saveWallet(setup.draft, at: setup.now)

        let deletions = try await [
            setup.database.deleteWallet(first.id, at: setup.now),
            setup.database.deleteWallet(second.id, at: setup.now)
        ]

        let merged = Deletion(merging: deletions)

        #expect(merged.subject?.count == 2)
        #expect(Deletion(merging: []).subject == nil)
    }
}

private extension DeletionSubjectTests {
    static func draft(
        memo: String,
        categoryId: EntryCategory.ID,
        walletId: Wallet.ID,
        on day: LocalDate
    ) -> RecurringDraft {
        RecurringDraft(
            type: .expense,
            amount: 80000,
            categoryId: categoryId,
            walletId: walletId,
            memo: memo,
            frequency: .monthly,
            month: 1,
            day: 27,
            startDate: day
        )
    }
}

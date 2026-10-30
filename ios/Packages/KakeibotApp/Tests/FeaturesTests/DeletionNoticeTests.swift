import Core
import Features
import Foundation
import Store
import Testing

struct DeletionNoticeTests {
    @Test
    func namesSingleDeletedItem() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        let wallet = try #require(try await database.entryOptions().wallets.last)

        let deletion = try await database.deleteWallet(wallet.id, at: Date())

        #expect(deletion.subject?.noticeMessage == "\(wallet.name) を削除しました")
    }

    @Test
    func fallsBackToKindAndCount() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        let options = try await database.entryOptions()
        let wallets = options.wallets
        let day = try #require(LocalDate("2026-11-01"))

        let draft = RecurringDraft(
            type: .expense,
            amount: 80000,
            categoryId: options.expenseCategories[0].id,
            walletId: wallets[0].id,
            frequency: .monthly,
            month: 1,
            day: 27,
            startDate: day
        )

        let recurring = try await database.saveRecurring(draft, today: day, at: Date())
        let unnamed = try await database.deleteRecurring(recurring.id, at: Date())

        let walletDraft = WalletDraft(
            kind: .cash,
            name: "小銭入れ",
            mark: .glyph(.cash),
            color: "#C9A465",
            initialBalance: 0
        )

        let added = try await database.saveWallet(walletDraft, at: Date())

        let deletions = try await [
            database.deleteWallet(added.id, at: Date()),
            database.deleteWallet(wallets[1].id, at: Date())
        ]

        let merged = Deletion(merging: deletions)

        #expect(unnamed.subject?.noticeMessage == "固定費を削除しました")
        #expect(merged.subject?.noticeMessage == "口座 2 件を削除しました")
    }
}

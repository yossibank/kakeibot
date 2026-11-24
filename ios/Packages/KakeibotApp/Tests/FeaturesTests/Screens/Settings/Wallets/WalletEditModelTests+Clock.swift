import Core
import FeatureModels
import Features
import Foundation
import Store
import Testing

extension WalletEditModelTests {
    @Test
    func countsBalanceThroughClockToday() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let bank = try await setup.wallet(named: "銀行")
        let noon = Date(timeIntervalSince1970: 1_791_774_000)
        let nextNoon = noon.addingTimeInterval(86400)
        let tomorrow = LocalDate(nextNoon, in: .current)

        let expense = EntryDraft(
            type: .expense,
            amount: 400,
            date: tomorrow,
            categoryId: options.expenseCategories[0].id,
            walletId: bank.id
        )

        try await setup.database.saveEntry(expense, at: noon)
        let today = WalletEditModel(
            parts: ScreenParts(database: setup.database, clock: .fixed(noon)),
            editing: bank.id
        )
        let nextDay = WalletEditModel(
            parts: ScreenParts(database: setup.database, clock: .fixed(nextNoon)),
            editing: bank.id
        )

        await today.load()
        await nextDay.load()

        #expect(today.input.balance - nextDay.input.balance == 400)
    }
}

import Core
import FeatureModels
import Features
import Foundation
import Store
import Testing

extension EntryModelTests {
    @Test
    func takesTodayFromClock() async throws {
        let setup = try await Setup()
        let model = try await Self.fixedModel(setup)
        let today = LocalDate(Self.fixedNow, in: .current)

        #expect(model.state.today == today)
        #expect(model.output.monthOverview.period.contains(today))
        #expect(model.output.monthTotalText == "今月の食費 ¥500")
    }

    @Test
    func remakesMonthWhenTodayChanges() async throws {
        let setup = try await Setup()
        let model = try await Self.fixedModel(setup)
        let today = LocalDate(Self.fixedNow, in: .current)
        let later = today.adding(days: 40)

        model.state.today = later

        #expect(model.output.monthOverview.period.contains(later))
        #expect(!model.output.monthOverview.period.contains(today))
        #expect(model.output.monthTotalText == "今月の食費 ¥0")
    }
}

private extension EntryModelTests {
    static let fixedNow = Date(timeIntervalSince1970: 1_791_774_000)

    static func fixedModel(_ setup: Setup) async throws -> EntryModel {
        let options = try await setup.database.entryOptions()
        let wallet = try #require(options.wallets.first?.id)
        let category = try #require(options.expenseCategories.first?.id)
        let today = LocalDate(fixedNow, in: .current)

        let draft = EntryDraft(
            type: .expense,
            amount: 500,
            date: today,
            categoryId: category,
            walletId: wallet
        )

        try await setup.database.saveEntry(draft, at: fixedNow)

        let model = EntryModel(
            parts: ScreenParts(database: setup.database, clock: .fixed(fixedNow)),
            date: today
        )

        await model.load()

        return model
    }
}

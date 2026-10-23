import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct OnboardingModelTests {
    @Test
    func walksFullRouteAndSavesChoices() async throws {
        let setup = try await HomeModelTests.Setup()
        let payday = try #require(MonthStartDay(25))

        let model = OnboardingModel(
            database: setup.database,
            today: setup.today
        )

        await model.load()
        let first = model.isFirstPage
        let locked = model.canTurn(forward: true)
        model.choose(.full)
        model.next()
        await model.monthStart.choose(payday)
        model.next()
        await model.refreshPage()
        let budgetMonth = model.budget.month
        model.back()
        let back = model.page
        model.next()
        model.next()
        let title = model.nextTitle
        let finished = await model.finish()
        let startsWithAmount = try await setup.database.setting(.entryStartsWithAmount)
        let completed = try await setup.database.setting(.onboardingCompleted)

        #expect(first)
        #expect(!locked)
        #expect(budgetMonth == YearMonth(year: 2026, month: 10))
        #expect(back == .monthStart)
        #expect(model.page == .setup)
        #expect(model.isLastPage)
        #expect(title == "はじめる")
        #expect(finished)
        #expect(startsWithAmount)
        #expect(completed)
    }

    @Test
    func endsMinimalRouteAtBudget() async throws {
        let setup = try await HomeModelTests.Setup()

        let model = OnboardingModel(
            database: setup.database,
            today: setup.today
        )

        model.choose(.minimal)
        model.next()
        model.next()

        #expect(model.page == .budget)
        #expect(model.isLastPage)
        #expect(!model.canTurn(forward: true))
    }

    @Test
    func addsStarterTemplatesOnce() async throws {
        let setup = try await HomeModelTests.Setup()

        let model = OnboardingModel(
            database: setup.database,
            today: setup.today
        )

        await model.load()
        await model.load()
        let templates = try await setup.database.templates()
        let options = try await setup.database.entryOptions()
        let cash = options.wallets.first { $0.kind == .cash }

        #expect(templates.map(\.name) == ["コンビニ", "ランチ", "電車", "日用品"])
        #expect(templates.allSatisfy { $0.amount == nil })
        #expect(templates.allSatisfy { $0.walletId == cash?.id })
    }
}

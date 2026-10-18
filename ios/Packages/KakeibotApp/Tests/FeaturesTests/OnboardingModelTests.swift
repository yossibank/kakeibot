import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct OnboardingModelTests {
    @Test
    func walksPagesAndSavesChoices() async throws {
        let setup = try await HomeModelTests.Setup()
        let payday = try #require(MonthStartDay(25))

        let model = OnboardingModel(
            database: setup.database,
            today: setup.today
        )

        await model.load()
        let first = model.isFirstPage
        model.next()
        await model.monthStart.choose(payday)
        model.next()
        await model.refreshPage()
        let budgetMonth = model.budget.month
        model.back()
        let back = model.page
        model.next()
        model.next()
        model.launchScreen = .entry
        let title = model.nextTitle
        let finished = await model.finish()
        let launchScreen = try await setup.database.setting(.launchScreen)
        let completed = try await setup.database.setting(.onboardingCompleted)

        #expect(first)
        #expect(budgetMonth == YearMonth(year: 2026, month: 10))
        #expect(back == .monthStart)
        #expect(model.isLastPage)
        #expect(title == "はじめる")
        #expect(finished)
        #expect(launchScreen == .entry)
        #expect(completed)
    }
}

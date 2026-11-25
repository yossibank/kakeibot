import Core
import FeatureModels
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
            parts: .system(setup.database),
            today: setup.today,
            newsVersion: WhatsNewRelease.latestVersion
        )

        await model.load()
        let first = model.output.isFirstPage
        let locked = model.canTurn(forward: true)
        model.choose(.full)
        model.next()
        await model.state.monthStart.choose(payday)
        model.next()
        await model.refreshPage()
        let budgetMonth = model.state.budget.input.month
        model.back()
        let back = model.state.page
        model.next()
        model.next()
        let title = model.output.nextTitle
        let outcomeBefore = model.state.outcome
        let finished = await model.finish()
        let completed = try await setup.database.setting(.onboardingCompleted)
        let seenNews = try await setup.database.setting(.whatsNewSeenVersion)

        #expect(model.state.outcome != outcomeBefore)
        #expect(first)
        #expect(!locked)
        #expect(budgetMonth == YearMonth(year: 2026, month: 10))
        #expect(back == .monthStart)
        #expect(model.state.page == .setup)
        #expect(model.output.isLastPage)
        #expect(title == "はじめる")
        #expect(finished)
        #expect(completed)
        #expect(seenNews == WhatsNewRelease.latestVersion)
    }

    @Test
    func opensSetupItemOnPath() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = OnboardingModel(
            parts: .system(setup.database),
            today: setup.today,
            newsVersion: WhatsNewRelease.latestVersion
        )

        model.state.open(.wallets)

        #expect(model.state.path == [.wallets])
    }

    @Test
    func endsMinimalRouteAtBudget() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = OnboardingModel(
            parts: .system(setup.database),
            today: setup.today,
            newsVersion: WhatsNewRelease.latestVersion
        )

        model.choose(.minimal)
        model.next()
        model.next()

        #expect(model.state.page == .budget)
        #expect(model.output.stepPages == [.monthStart, .budget])
        #expect(model.output.isLastPage)
        #expect(!model.canTurn(forward: true))
    }

    @Test
    func addsStarterTemplatesOnce() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = OnboardingModel(
            parts: .system(setup.database),
            today: setup.today,
            newsVersion: WhatsNewRelease.latestVersion
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

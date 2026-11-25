import Core
@testable import FeatureModels
import Store
import Testing

@MainActor
struct MainModelTests {
    @Test
    func choosesLaunchTabFromSetting() async throws {
        let setup = try await TemplateSetup()
        try await setup.database.setSetting(.launchScreen, to: .review)
        let model = Self.model(setup)

        let beforeStart = model.input.launchScreen
        await model.start(choosesTab: true)

        #expect(beforeStart == nil)
        #expect(model.input.launchScreen == .review)
        #expect(model.state.tab == .review)
        #expect(model.state.visitedTabs == [.home, .review])
    }

    @Test
    func keepsHomeTabWhenLaunchTabIsNotChosen() async throws {
        let setup = try await TemplateSetup()
        try await setup.database.setSetting(.launchScreen, to: .assets)
        let model = Self.model(setup)

        await model.start(choosesTab: false)

        #expect(model.input.launchScreen == .assets)
        #expect(model.state.tab == .home)
        #expect(model.state.visitedTabs == [.home])
    }

    @Test
    func opensEntrySheetAtLaunch() async throws {
        let setup = try await TemplateSetup()
        let home = Self.model(setup)
        await home.start(choosesTab: true)
        try await setup.database.setSetting(.launchScreen, to: .entry)
        let entry = Self.model(setup)
        await entry.start(choosesTab: true)
        let preferred = Self.model(setup)
        await preferred.start(choosesTab: false)

        home.openLaunchSheet(preferring: nil)
        entry.openLaunchSheet(preferring: nil)
        preferred.openLaunchSheet(preferring: .settings)

        #expect(home.state.sheet == nil)
        #expect(entry.state.sheet == .new)
        #expect(entry.state.tab == .home)
        #expect(preferred.state.sheet == .settings)
    }

    @Test
    func opensHomeRouteWithoutWaiting() async throws {
        let setup = try await TemplateSetup()
        let model = Self.model(setup)
        model.state.select(.records)
        var tabAfterRoute: MainModel.Tab?

        let route = model.perform {
            await $0.open(.home)
        }
        let probe = model.perform {
            tabAfterRoute = $0.state.tab
        }

        await route.value
        await probe.value

        #expect(tabAfterRoute == .home)
        #expect(model.state.sheet == nil)
        #expect(model.state.visitedTabs == [.home, .records])
    }

    @Test
    func opensEntryRouteOnHomeWithDate() async throws {
        let setup = try await TemplateSetup()
        let model = Self.model(setup)
        let date = setup.date.adding(days: -2)
        model.state.select(.assets)

        await model.open(.entry(date))

        #expect(model.state.tab == .home)
        #expect(model.state.sheet == .new)
        #expect(model.state.draft.state.payment.date == date)
        #expect(!model.state.startsReceipt)
    }

    @Test
    func opensRecurringRouteOnCurrentTab() async throws {
        let setup = try await TemplateSetup()
        let model = Self.model(setup)
        let id = Recurring.ID()
        model.state.select(.review)

        await model.open(.recurring(id))

        #expect(model.state.tab == .review)
        #expect(model.state.sheet == .recurring(id))
    }

    @Test
    func opensTemplateRouteWithSavedTemplate() async throws {
        let setup = try await TemplateSetup()
        try await setup.saveTemplate(name: "ランチ", amount: nil)
        let lunch = try #require(await setup.database.templates().first)
        let model = Self.model(setup)
        model.state.select(.records)

        await model.open(.template(lunch.id))
        let found = model.state.sheet
        await model.open(.template(EntryTemplate.ID()))

        #expect(found == .template(lunch))
        #expect(model.state.tab == .home)
        #expect(model.state.sheet == nil)
    }

    @Test
    func opensNewTemplateRouteOnHome() async throws {
        let setup = try await TemplateSetup()
        let model = Self.model(setup)
        model.state.select(.records)

        await model.open(.newTemplate)

        #expect(model.state.tab == .home)
        #expect(model.state.sheet == .newTemplate)
    }

    @Test
    func opensReceiptRouteAndStartsReading() async throws {
        let setup = try await TemplateSetup()
        let model = Self.model(setup)
        model.addEntry(on: setup.date.adding(days: -3))
        model.state.sheet = nil

        await model.open(.receipt)
        let startsAfterRoute = model.state.startsReceipt
        let dateAfterRoute = model.state.draft.state.payment.date
        await model.prepareDraft().value

        #expect(startsAfterRoute)
        #expect(dateAfterRoute == setup.date)
        #expect(model.state.sheet == .new)
        #expect(model.state.tab == .home)
        #expect(!model.state.startsReceipt)
    }
}

extension MainModelTests {
    struct Seen: Equatable {
        var sheet: MainModel.Sheet?
        var tab: MainModel.Tab
    }

    static func model(_ setup: TemplateSetup) -> MainModel {
        MainModel(
            parts: .system(setup.database),
            today: setup.date,
            closeDelay: .zero
        )
    }

    static func seen(in model: MainModel) -> Seen {
        Seen(sheet: model.state.sheet, tab: model.state.tab)
    }
}

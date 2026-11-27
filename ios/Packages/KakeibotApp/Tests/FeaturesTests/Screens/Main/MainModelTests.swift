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
        #expect(model.state.tabs.current == .review)
        #expect(model.state.tabs.visited == [.home, .review])
    }

    @Test
    func keepsHomeTabWhenLaunchTabIsNotChosen() async throws {
        let setup = try await TemplateSetup()
        try await setup.database.setSetting(.launchScreen, to: .assets)
        let model = Self.model(setup)

        await model.start(choosesTab: false)

        #expect(model.input.launchScreen == .assets)
        #expect(model.state.tabs.current == .home)
        #expect(model.state.tabs.visited == [.home])
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

        #expect(home.state.presented.sheet.current == nil)
        #expect(entry.state.presented.sheet.current == .new)
        #expect(entry.state.tabs.current == .home)
        #expect(preferred.state.presented.sheet.current == .settings)
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
            tabAfterRoute = $0.state.tabs.current
        }

        await route.value
        await probe.value

        #expect(tabAfterRoute == .home)
        #expect(model.state.presented.sheet.current == nil)
        #expect(model.state.tabs.visited == [.home, .records])
    }

    @Test
    func opensEntryRouteOnHomeWithDate() async throws {
        let setup = try await TemplateSetup()
        let model = Self.model(setup)
        let date = setup.date.adding(days: -2)
        model.state.select(.assets)

        await model.open(.entry(date))

        #expect(model.state.tabs.current == .home)
        #expect(model.state.presented.sheet.current == .new)
        #expect(model.state.submodels.draft.state.payment.date == date)
        #expect(!model.state.entry.startsReceipt)
    }

    @Test
    func opensRecurringRouteOnCurrentTab() async throws {
        let setup = try await TemplateSetup()
        let model = Self.model(setup)
        let id = Recurring.ID()
        model.state.select(.review)

        await model.open(.recurring(id))

        #expect(model.state.tabs.current == .review)
        #expect(model.state.presented.sheet.current == .recurring(id))
    }

    @Test
    func opensTemplateRouteWithSavedTemplate() async throws {
        let setup = try await TemplateSetup()
        try await setup.saveTemplate(name: "ランチ", amount: nil)
        let lunch = try #require(await setup.database.templates().first)
        let model = Self.model(setup)
        model.state.select(.records)

        await model.open(.template(lunch.id))
        let found = model.state.presented.sheet.current
        await model.open(.template(EntryTemplate.ID()))

        #expect(found == .template(lunch))
        #expect(model.state.tabs.current == .home)
        #expect(model.state.presented.sheet.current == nil)
    }

    @Test
    func opensNewTemplateRouteOnHome() async throws {
        let setup = try await TemplateSetup()
        let model = Self.model(setup)
        model.state.select(.records)

        await model.open(.newTemplate)

        #expect(model.state.tabs.current == .home)
        #expect(model.state.presented.sheet.current == .newTemplate)
    }

    @Test
    func opensReceiptRouteAndStartsReading() async throws {
        let setup = try await TemplateSetup()
        let model = Self.model(setup)
        model.addEntry(on: setup.date.adding(days: -3))
        model.state.presented.sheet.closeAll()

        await model.open(.receipt)
        let startsAfterRoute = model.state.entry.startsReceipt
        let dateAfterRoute = model.state.submodels.draft.state.payment.date
        await model.prepareDraft().value

        #expect(startsAfterRoute)
        #expect(dateAfterRoute == setup.date)
        #expect(model.state.presented.sheet.current == .new)
        #expect(model.state.tabs.current == .home)
        #expect(!model.state.entry.startsReceipt)
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
            closeDelay: .zero,
            warmupDuration: .zero
        )
    }

    static func seen(in model: MainModel) -> Seen {
        Seen(sheet: model.state.presented.sheet.current, tab: model.state.tabs.current)
    }
}

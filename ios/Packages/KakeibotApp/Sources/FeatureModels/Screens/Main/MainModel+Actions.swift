import Core
import Store

public extension MainModel {
    func start(choosesTab: Bool) async {
        let screen = await (try? dependencies.parts.database.setting(.launchScreen)) ?? .home

        if choosesTab {
            state.select(Self.tab(for: screen))
        }

        input.launchScreen = screen
    }

    func warmUpEntry() async {
        try? await Task.sleep(for: dependencies.warmupDuration)
        state.finishWarmingEntry()
    }

    func openLaunchSheet(preferring sheet: Sheet?) {
        if let sheet {
            state.sheet = sheet
        } else if input.launchScreen == .entry {
            state.sheet = .new
        }
    }

    func open(_ route: PlannedNotification.Route) async {
        if state.sheet != nil {
            await closeSheet()
        }

        switch route {
        case .home:
            state.select(.home)

        case let .entry(date):
            state.select(.home)
            state.draft.state.setDate(date)
            state.sheet = .new

        case let .recurring(id):
            state.sheet = .recurring(id)

        case let .template(id):
            state.select(.home)
            state.sheet = await templateSheet(id)

        case .newTemplate:
            state.select(.home)
            state.sheet = .newTemplate

        case .receipt:
            state.select(.home)
            state.draft.state.setDate(state.today)
            state.startReceipt()
            state.sheet = .new
        }
    }

    func move(
        to tab: Tab?,
        opening sheet: Sheet?
    ) async {
        await closeSheet()

        if let tab {
            state.select(tab)
        }

        if let sheet {
            state.sheet = sheet
        }
    }

    func addEntry(on date: LocalDate) {
        state.draft.state.setDate(date)
        state.sheet = .new
    }

    func addTransfer() {
        state.draft.select(.transfer)
        state.sheet = .transfer
    }

    @discardableResult
    func prepareDraft() -> Task<Void, Never> {
        let draft = EntryModel(parts: dependencies.parts, date: state.today)

        state.replaceDraft(with: draft)

        return draft.perform {
            await $0.load()
        }
    }

    @discardableResult
    func setToday(_ today: LocalDate) -> Task<Void, Never> {
        state.draft.state.today = today
        state.setToday(today)

        return prepareDraft()
    }
}

private extension MainModel {
    static func tab(for screen: LaunchScreen) -> Tab {
        switch screen {
        case .home, .entry: .home
        case .records: .records
        case .review: .review
        case .assets: .assets
        }
    }

    func closeSheet() async {
        state.sheet = nil
        try? await Task.sleep(for: dependencies.closeDelay)
    }

    func templateSheet(_ id: EntryTemplate.ID) async -> Sheet? {
        let templates = await (try? dependencies.parts.database.templates()) ?? []

        return templates
            .first { $0.id == id }
            .map { .template($0) }
    }
}

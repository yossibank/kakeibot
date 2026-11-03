import Core
import Features
import Store
import SwiftUI

extension MainView {
    var isLoaded: Bool {
        let isHomeLoaded = home.list != nil || home.errorNotice.message != nil
        let isSetupLoaded = setup.isLoaded || setup.errorNotice.message != nil

        return isHomeLoaded && isSetupLoaded && launchScreen != nil && areTabsLoaded
    }

    var templateOrderBinding: Binding<TemplateOrder> {
        Binding {
            home.templateOrder
        } set: { order in
            Task {
                await home.setTemplateOrder(order)
            }
        }
    }

    func chooseLaunchTab() async {
        let screen = await (try? database.setting(.launchScreen)) ?? .home

        if route == nil,
           !hasLaunchSheet {
            switch screen {
            case .home, .entry: tab = .home
            case .records: tab = .records
            case .review: tab = .review
            case .assets: tab = .assets
            }
        }

        launchScreen = screen
    }

    func openLaunchSheet() {
        guard route == nil else {
            return
        }

        #if DEBUG
        if let launchSheet = Sheet.launchArgument {
            sheet = launchSheet
            return
        }
        #endif

        if launchScreen == .entry {
            sheet = .new
        }
    }

    func addEntry(on date: LocalDate) {
        draft.date = date
        sheet = .new
    }

    func markOpened(_ sheet: Sheet?) async {
        guard sheet == .new else {
            return
        }

        await setup.markEntryOpened()
    }

    func open(_ route: PlannedNotification.Route) {
        onRouteOpened()

        Task {
            if sheet != nil {
                sheet = nil
                try? await Task.sleep(for: Self.sheetCloseDuration)
            }

            switch route {
            case .home:
                tab = .home
            case let .entry(date):
                tab = .home
                draft.date = date
                sheet = .new
            case let .recurring(id):
                sheet = .recurring(id)
            case let .template(id):
                tab = .home
                sheet = await templateSheet(id)
            }
        }
    }

    func openNews() {
        sheet = .whatsNew(seenVersion: setup.seenNewsVersion)

        Task {
            await setup.markNewsSeen()
        }
    }

    func tryFeature(_ action: WhatsNewRelease.Action) {
        Task {
            sheet = nil
            try? await Task.sleep(for: Self.sheetCloseDuration)

            switch action {
            case .entry:
                tab = .home
                sheet = .new
            case let .setup(item):
                sheet = .setup(item)
            }
        }
    }

    func useTemplate(_ template: EntryTemplate) {
        guard template.amount != nil else {
            sheet = .template(template)
            return
        }

        sheet = nil

        Task {
            if let change = await home.record(template) {
                show(change)
            }
        }
    }

    func show(_ change: EntryChange) {
        let request = AppReviewRequest(database: database)

        notice.show(change)

        Task {
            guard await request.shouldAsk(after: change, at: Date()) else {
                return
            }

            try? await Task.sleep(for: Self.sheetCloseDuration)
            requestReview()
        }
    }

    func prepareDraft() {
        let model = EntryModel(database: database, date: today)

        draft = model

        Task {
            await model.load()
        }
    }
}

private extension MainView {
    static let sheetCloseDuration: Duration = .milliseconds(600)

    var areTabsLoaded: Bool {
        let isRecordsLoaded = records.list != nil || records.errorNotice.message != nil
        let isReviewLoaded = review.list != nil || review.errorNotice.message != nil
        let isAssetsLoaded = assets.list != nil || assets.errorNotice.message != nil

        return isRecordsLoaded && isReviewLoaded && isAssetsLoaded
    }

    var hasLaunchSheet: Bool {
        #if DEBUG
        Sheet.launchArgument != nil
        #else
        false
        #endif
    }

    func templateSheet(_ id: EntryTemplate.ID) async -> Sheet? {
        let templates = await (try? database.templates()) ?? []

        return templates
            .first { $0.id == id }
            .map { .template($0) }
    }
}

#if DEBUG
private extension MainView.Sheet {
    static var launchArgument: Self? {
        let arguments = ProcessInfo.processInfo.arguments

        guard
            let index = arguments.firstIndex(of: "-open"),
            arguments.indices.contains(index + 1)
        else {
            return nil
        }

        let name = arguments[index + 1]

        guard name != "settings" else {
            return .settings
        }

        return SetupItem(rawValue: name).map { .setup($0) }
    }
}
#endif

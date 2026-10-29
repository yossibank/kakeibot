import Core
import Features
import Foundation
import Store
import SwiftUI

extension MainView {
    var isLoaded: Bool {
        let isHomeLoaded = home.list != nil || home.errorNotice.message != nil
        let isSetupLoaded = setup.isLoaded || setup.errorNotice.message != nil

        return isHomeLoaded && isSetupLoaded
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

    func openLaunchScreen() async {
        let screen = await (try? database.setting(.launchScreen)) ?? .home

        guard route == nil else {
            return
        }

        #if DEBUG
        if let launchSheet = Sheet.launchArgument {
            sheet = launchSheet
            return
        }
        #endif

        switch screen {
        case .home: tab = .home
        case .records: tab = .records
        case .review: tab = .review
        case .assets: tab = .assets
        case .entry: sheet = .new
        }
    }

    func markOpened(_ sheet: Sheet?) async {
        switch sheet {
        case .new: await setup.markEntryOpened()
        case .settings: await setup.markSettingsOpened()
        default: break
        }
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

    func useTemplate(_ template: EntryTemplate) {
        guard template.amount != nil else {
            sheet = .template(template)
            return
        }

        sheet = nil

        Task {
            if let change = await home.record(template) {
                notice.show(change)
            }
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

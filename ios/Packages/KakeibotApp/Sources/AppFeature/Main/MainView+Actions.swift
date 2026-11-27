import Core
import DesignSystem
import FeatureModels
import Features
import SwiftUI

extension MainView {
    var isLoaded: Bool {
        let isHomeLoaded = Self.isSettled(home.input.list, home.state.notices.error)
        let isSetupLoaded = setup.output.isLoaded || setup.state.errorNotice.message != nil
        let isLaunchChosen = model.input.launchScreen != nil
        return isHomeLoaded && isSetupLoaded && isLaunchChosen && areTabsLoaded
    }

    var templateOrderBinding: Binding<TemplateOrder> {
        Binding {
            home.input.templateOrder
        } set: { order in
            home.perform {
                await $0.setTemplateOrder(order)
            }
        }
    }

    func chooseLaunchTab() async {
        let choosesTab = route == nil && Self.launchSheet == nil
        await model.start(choosesTab: choosesTab)
    }

    func openLaunchSheet() {
        guard route == nil else {
            return
        }

        model.openLaunchSheet(preferring: Self.launchSheet)
    }

    func openEntry(_ id: Entry.ID) {
        model.state.presented.sheet.show(.edit(id))
    }

    func openRecurring(_ id: Recurring.ID) {
        model.state.presented.sheet.show(.recurring(id))
    }

    func openRecurrings() {
        model.state.presented.sheet.show(.periodRecurrings)
    }

    func showDay(_ date: LocalDate) {
        records.open(date)
        model.state.select(.records)
    }

    func retry() {
        model.state.round.restart()
    }

    func observe() async {
        let models = (home, records, review, assets, setup)

        await model.state.round.each([
            { await models.0.run() },
            { await models.1.run() },
            { await models.2.run() },
            { await models.3.run() },
            { await models.4.run() }
        ])
    }

    func markOpened(_ sheet: MainModel.Sheet?) {
        guard sheet == .new else {
            return
        }

        setup.perform {
            await $0.markEntryOpened()
        }
    }

    func open(_ route: PlannedNotification.Route) {
        onRouteOpened()

        model.perform {
            await $0.open(route)
        }
    }

    func openNews() {
        model.state.presented.sheet.show(.whatsNew(seenVersion: setup.output.seenNewsVersion))

        setup.perform {
            await $0.markNewsSeen()
        }
    }

    func tryFeature(_ action: WhatsNewRelease.Action) {
        let destination = Self.destination(of: action)

        model.perform {
            await $0.move(to: destination.tab, opening: destination.sheet)
        }
    }

    func useTemplate(_ template: EntryTemplate) {
        guard template.amount != nil else {
            model.state.presented.sheet.show(.template(template))
            return
        }

        model.state.presented.sheet.closeAll()

        home.perform {
            await $0.record(template)
        }
    }

    func show(_ change: EntryChange) {
        notice.show(change)

        appReview.perform {
            await $0.ask(after: change)
        }
    }
}

private extension MainView {
    static var launchSheet: MainModel.Sheet? {
        #if DEBUG
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
        #else
        nil
        #endif
    }

    var areTabsLoaded: Bool {
        let isRecordsLoaded = Self.isSettled(records.input.list, records.state.notices.error)
        let isReviewLoaded = Self.isSettled(review.input.list, review.state.notices.error)
        let isAssetsShown = assets.output.list != nil || assets.input.list.isFailed
        let isAssetsLoaded = isAssetsShown || assets.state.notices.error.message != nil
        return isRecordsLoaded && isReviewLoaded && isAssetsLoaded
    }

    static func isSettled(
        _ list: Loadable<some Any>,
        _ notice: ErrorNotice
    ) -> Bool {
        list.isSettled || notice.message != nil
    }

    static func destination(
        of action: WhatsNewRelease.Action
    ) -> (tab: MainModel.Tab?, sheet: MainModel.Sheet?) {
        switch action {
        case .entry: (.home, .new)
        case .records: (.records, nil)
        case .review: (.review, nil)
        case .assets: (.assets, nil)
        case let .setup(item): (nil, .setup(item))
        }
    }
}

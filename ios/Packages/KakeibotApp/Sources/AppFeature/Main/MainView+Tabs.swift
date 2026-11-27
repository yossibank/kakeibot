import Core
import DesignSystem
import FeatureModels
import Features
import SwiftUI

extension MainView {
    var homeTab: some View {
        MainTabLayer(state: model.state, value: .home) {
            HomeView(
                model: home,
                setup: setup,
                appIcon: appIcon,
                isSheetOpen: model.state.presented.sheet.current != nil,
                onOpenEntry: openEntry,
                onShowRecords: {
                    records.openCurrentMonth()

                    model.state.select(.records)
                },
                onAddEntry: model.addEntry(on:),
                onRetry: retry,
                onOpenSettings: {
                    model.state.presented.sheet.show(.settings)
                },
                onOpenNews: openNews,
                onUseTemplate: useTemplate,
                onShowAllTemplates: {
                    model.state.presented.sheet.show(.templates)
                },
                onOpenOrderMenu: { frame in
                    withAnimation(.snappy(duration: 0.25)) {
                        layout.orderMenuAnchor = frame
                    }
                },
                onAddTemplate: {
                    model.state.presented.sheet.show(.newTemplate)
                },
                onDeleteEntry: { id in
                    notice.perform {
                        await $0.delete(id, in: home.input.list.value)
                    }
                },
                onOpenRecurrings: openRecurrings,
                onOpenRecurring: openRecurring,
                onOpenSetup: { item in
                    model.state.presented.sheet.show(.setup(item))
                },
                onOpenDay: showDay
            )
            .tabScreen(home, round: model.state.round)
            .tabContent()
        }
    }

    var recordsTab: some View {
        MainTabLayer(state: model.state, value: .records) {
            RecordsView(
                model: records,
                onOpenEntry: openEntry,
                onAddEntry: model.addEntry(on:),
                onOpenRecurring: openRecurring,
                onChangeEntries: { ids, change in
                    notice.perform {
                        await $0.changeEntries(ids, to: change)
                    }
                },
                onDeleteEntries: { ids in
                    notice.perform {
                        await $0.deleteEntries(ids)
                    }
                },
                onDeleteAdjustment: model.receive
            )
            .tabScreen(records, round: model.state.round)
            .tabContent()
        }
    }

    var reviewTab: some View {
        MainTabLayer(state: model.state, value: .review) {
            ReviewView(
                model: review,
                onOpenEntry: openEntry,
                onOpenRecurring: openRecurring,
                onOpenDay: showDay,
                onAddEntry: model.addEntry(on:),
                onOpenRecurrings: openRecurrings
            )
            .tabScreen(review, round: model.state.round)
            .tabContent()
        }
    }

    var assetsTab: some View {
        MainTabLayer(state: model.state, value: .assets) {
            AssetsView(
                model: assets,
                onTransfer: model.addTransfer,
                onOpenWallet: { id in
                    model.state.presented.sheet.show(.wallet(id))
                },
                onOpenRecurring: openRecurring,
                onOpenEntry: openEntry,
                onMarkReward: {
                    model.state.presented.sheet.show(.reward)
                }
            )
            .tabScreen(assets, round: model.state.round)
            .tabContent()
        }
    }
}

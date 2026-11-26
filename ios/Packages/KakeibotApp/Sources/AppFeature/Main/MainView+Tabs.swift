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
                isSheetOpen: model.state.sheet != nil,
                onOpenEntry: openEntry,
                onShowRecords: {
                    records.openCurrentMonth()

                    model.state.select(.records)
                },
                onAddEntry: model.addEntry(on:),
                onRetry: retry,
                onOpenSettings: {
                    model.state.sheet = .settings
                },
                onOpenNews: openNews,
                onUseTemplate: useTemplate,
                onShowAllTemplates: {
                    model.state.sheet = .templates
                },
                onOpenOrderMenu: { frame in
                    withAnimation(.snappy(duration: 0.25)) {
                        layout.orderMenuAnchor = frame
                    }
                },
                onAddTemplate: {
                    model.state.sheet = .newTemplate
                },
                onDeleteEntry: { id in
                    notice.perform {
                        await $0.delete(id, in: home.input.list.value)
                    }
                },
                onOpenRecurrings: openRecurrings,
                onOpenRecurring: openRecurring,
                onOpenSetup: { item in
                    model.state.sheet = .setup(item)
                },
                onOpenDay: showDay
            )
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
            .loadFailed(records.input.list.isFailed, onRetry: retry)
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
            .loadFailed(review.input.list.isFailed, onRetry: retry)
            .tabContent()
        }
    }

    var assetsTab: some View {
        MainTabLayer(state: model.state, value: .assets) {
            AssetsView(
                model: assets,
                onTransfer: model.addTransfer,
                onOpenWallet: { id in
                    model.state.sheet = .wallet(id)
                },
                onOpenRecurring: openRecurring,
                onOpenEntry: openEntry,
                onMarkReward: {
                    model.state.sheet = .reward
                }
            )
            .loadFailed(assets.input.list.isFailed, onRetry: retry)
            .tabContent()
        }
    }
}

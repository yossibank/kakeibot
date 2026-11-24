import Core
import DesignSystem
import Features
import SwiftUI

extension MainView {
    var homeTab: some View {
        MainTabLayer(selection: selection, value: .home) {
            HomeView(
                model: home,
                setup: setup,
                appIcon: appIcon,
                isSheetOpen: sheet != nil,
                onOpenEntry: openEntry,
                onShowRecords: {
                    records.openCurrentMonth()

                    tab = .records
                },
                onAddEntry: addEntry(on:),
                onRetry: retry,
                onOpenSettings: {
                    sheet = .settings
                },
                onOpenNews: openNews,
                onUseTemplate: useTemplate,
                onShowAllTemplates: {
                    sheet = .templates
                },
                onOpenOrderMenu: { frame in
                    withAnimation(.snappy(duration: 0.25)) {
                        orderMenuAnchor = frame
                    }
                },
                onAddTemplate: {
                    sheet = .newTemplate
                },
                onDeleteEntry: { id in
                    Task {
                        await notice.delete(id, in: home.input.list)
                    }
                },
                onOpenRecurrings: openRecurrings,
                onOpenRecurring: openRecurring,
                onOpenSetup: { item in
                    sheet = .setup(item)
                },
                onOpenDay: showDay
            )
            .tabContent()
        }
    }

    var recordsTab: some View {
        MainTabLayer(selection: selection, value: .records) {
            RecordsView(
                model: records,
                onOpenEntry: openEntry,
                onAddEntry: addEntry(on:),
                onOpenRecurring: openRecurring,
                onChangeEntries: { ids, change in
                    Task {
                        await notice.changeEntries(ids, to: change)
                    }
                },
                onDeleteEntries: { ids in
                    Task {
                        await notice.deleteEntries(ids)
                    }
                },
                onDeleteAdjustment: { deletion in
                    undo.state.deletion = deletion
                }
            )
            .loadFailed(records.input.isListFailed, onRetry: retry)
            .tabContent()
        }
    }

    var reviewTab: some View {
        MainTabLayer(selection: selection, value: .review) {
            ReviewView(
                model: review,
                onOpenEntry: openEntry,
                onOpenRecurring: openRecurring,
                onOpenDay: showDay,
                onAddEntry: addEntry(on:),
                onOpenRecurrings: openRecurrings
            )
            .loadFailed(review.input.isListFailed, onRetry: retry)
            .tabContent()
        }
    }

    var assetsTab: some View {
        MainTabLayer(selection: selection, value: .assets) {
            AssetsView(
                model: assets,
                onTransfer: addTransfer,
                onOpenWallet: { id in
                    sheet = .wallet(id)
                },
                onOpenRecurring: openRecurring,
                onOpenEntry: openEntry,
                onMarkReward: {
                    sheet = .reward
                }
            )
            .loadFailed(assets.input.isListFailed, onRetry: retry)
            .tabContent()
        }
    }
}

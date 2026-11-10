import Core
import DesignSystem
import Features
import Store
import StoreKit
import SwiftUI

struct MainView: View {
    @State var selection = MainTabSelection()
    @State var sheet: Sheet?
    @State var home: HomeModel
    @State var records: RecordsModel
    @State var review: ReviewModel
    @State var assets: AssetsModel
    @State var setup: SetupModel
    @State var appIcon = AppIconListModel()
    @State var draft: EntryModel
    @State var notice: EntryNoticeModel
    @State var undo: DeletionUndo
    @State var launchScreen: LaunchScreen?

    @Environment(\.requestReview) var requestReview

    @State private var isWarmingEntry = true
    @State private var orderMenuAnchor: CGRect?
    @State private var observationRound = 0
    @State private var foreground = AppForegroundReturn()
    @State private var noticeRound = 0

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase

    let database: AppDatabase
    let today: LocalDate
    let route: PlannedNotification.Route?
    let onRouteOpened: () -> Void

    private let isRevealed: Bool
    private let onLoad: () -> Void

    init(
        database: AppDatabase,
        today: LocalDate,
        route: PlannedNotification.Route? = nil,
        isRevealed: Bool = true,
        onRouteOpened: @escaping () -> Void = {},
        onLoad: @escaping () -> Void = {}
    ) {
        _home = State(
            initialValue: HomeModel(
                database: database,
                today: today
            )
        )

        _records = State(
            initialValue: RecordsModel(
                database: database,
                today: today
            )
        )

        _review = State(
            initialValue: ReviewModel(
                database: database,
                today: today
            )
        )

        _assets = State(
            initialValue: AssetsModel(
                database: database,
                today: today
            )
        )

        _setup = State(initialValue: SetupModel(database: database))

        _draft = State(
            initialValue: EntryModel(
                database: database,
                date: today
            )
        )

        _notice = State(initialValue: EntryNoticeModel(database: database))

        _undo = State(initialValue: DeletionUndo(database: database))

        self.database = database
        self.today = today
        self.route = route
        self.isRevealed = isRevealed
        self.onRouteOpened = onRouteOpened
        self.onLoad = onLoad
    }

    var body: some View {
        ZStack {
            MainTabLayer(selection: selection, value: .home) {
                HomeView(
                    model: home,
                    setup: setup,
                    appIcon: appIcon,
                    isSheetOpen: sheet != nil,
                    onOpenEntry: { id in
                        sheet = .edit(id)
                    },
                    onShowRecords: {
                        records.openCurrentMonth()

                        tab = .records
                    },
                    onAddEntry: addEntry(on:),
                    onRetry: {
                        observationRound += 1
                    },
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
                            await notice.delete(id, in: home.list)
                        }
                    },
                    onOpenRecurrings: {
                        sheet = .periodRecurrings
                    },
                    onOpenRecurring: { id in
                        sheet = .recurring(id)
                    },
                    onOpenSetup: { item in
                        sheet = .setup(item)
                    },
                    onOpenDay: { date in
                        records.open(date)

                        tab = .records
                    }
                )
                .tabContent()
            }

            MainTabLayer(selection: selection, value: .records) {
                RecordsView(
                    model: records,
                    onOpenEntry: { id in
                        sheet = .edit(id)
                    },
                    onAddEntry: addEntry(on:),
                    onOpenRecurring: { id in
                        sheet = .recurring(id)
                    },
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
                        undo.deletion = deletion
                    }
                )
                .loadFailed(records.isListFailed) {
                    observationRound += 1
                }
                .tabContent()
            }

            MainTabLayer(selection: selection, value: .review) {
                ReviewView(
                    model: review,
                    onOpenEntry: { id in
                        sheet = .edit(id)
                    },
                    onOpenRecurring: { id in
                        sheet = .recurring(id)
                    },
                    onOpenDay: { date in
                        records.open(date)

                        tab = .records
                    },
                    onAddEntry: addEntry(on:)
                )
                .loadFailed(review.isListFailed) {
                    observationRound += 1
                }
                .tabContent()
            }

            MainTabLayer(selection: selection, value: .assets) {
                AssetsView(
                    model: assets,
                    onTransfer: {
                        sheet = .transfer
                    },
                    onOpenWallet: { id in
                        sheet = .wallet(id)
                    },
                    onOpenRecurring: { id in
                        sheet = .recurring(id)
                    },
                    onOpenEntry: { id in
                        sheet = .edit(id)
                    },
                    onMarkReward: {
                        sheet = .reward
                    }
                )
                .loadFailed(assets.isListFailed) {
                    observationRound += 1
                }
                .tabContent()
            }
        }
        .environment(\.noticeRound, noticeRound)
        .overlay(alignment: .leading) {
            if hasSidebar {
                MainTabBar(
                    selection: selection,
                    hasSidebar: true,
                    isAddHinted: !setup.isEntryOpened
                ) {
                    sheet = .new
                }
            }
        }
        .overlay(alignment: .bottom) {
            if !hasSidebar {
                MainTabBar(
                    selection: selection,
                    hasSidebar: false,
                    isAddHinted: !setup.isEntryOpened
                ) {
                    sheet = .new
                }
            }
        }
        .overlay {
            if let orderMenuAnchor {
                HomeTemplateOrderMenu(
                    selection: templateOrderBinding,
                    anchor: orderMenuAnchor
                ) {
                    withAnimation(.snappy(duration: 0.2)) {
                        self.orderMenuAnchor = nil
                    }
                }
                .transition(.opacity)
            }
        }
        .overlay {
            notices
        }
        .background {
            if isWarmingEntry {
                entryWarmup
            }

            MainLoadSignal {
                isLoaded
            } onLoad: {
                onLoad()
            }
        }
        .sheet(item: $sheet, onDismiss: prepareDraft) { sheet in
            sheetContent(for: sheet)
        }
        .task(id: observationRound) {
            await home.run()
        }
        .task(id: observationRound) {
            await records.run()
        }
        .task(id: observationRound) {
            await review.run()
        }
        .task(id: observationRound) {
            await assets.run()
        }
        .task(id: observationRound) {
            await setup.run()
        }
        .task {
            await draft.load()
        }
        .task {
            await chooseLaunchTab()
        }
        .task(id: isLaunchReady) {
            guard isLaunchReady else {
                return
            }

            if let route {
                open(route)
            } else {
                openLaunchSheet()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if foreground.receive(phase) {
                observationRound += 1
            }
        }
        .onChange(of: route) { _, route in
            if isRevealed,
               let route {
                open(route)
            }
        }
        .onChange(of: sheet) { _, sheet in
            Task {
                await markOpened(sheet)
            }
        }
        .onChange(of: today) { _, today in
            home.today = today
            records.today = today
            review.today = today
            assets.today = today

            prepareDraft()
        }
    }
}

extension MainView {
    var tab: MainTab {
        get {
            selection.value
        }
        nonmutating set {
            selection.value = newValue
        }
    }
}

private extension MainView {
    enum NoticeSource {
        case entry
        case deletion
        case undoError
        case tab
    }
}

private extension MainView {
    var notices: some View {
        let noticeAbove = Self.noticeAbove(hasSidebar: hasSidebar)
        let noticeBottom = Self.noticeBottom(hasSidebar: hasSidebar)

        return Color.clear
            .padding(.leading, Self.noticeLeading(hasSidebar: hasSidebar))
            .entryNotice(notice, above: noticeAbove)
            .deletionNotice($undo.deletion, bottom: noticeBottom) { deletion in
                Task {
                    await undo.restore(deletion)
                }
            }
            .errorBanner(undo.errorNotice, bottom: noticeBottom) {
                undo.errorNotice.clear()
            }
            .onChange(of: notice.notice) { _, new in
                if new != nil {
                    replaceNotices(with: .entry)
                }
            }
            .onChange(of: undo.deletion) { _, new in
                if new != nil {
                    replaceNotices(with: .deletion)
                }
            }
            .onChange(of: undo.errorNotice.count) {
                replaceNotices(with: .undoError)
            }
            .onChange(of: tabErrorCounts) {
                replaceNotices(with: .tab)
            }
    }

    var entryWarmup: some View {
        EntrySheet(model: draft)
            .opacity(0)
            .allowsHitTesting(false)
            .task {
                try? await Task.sleep(for: Self.warmupDuration)
                isWarmingEntry = false
            }
    }
}

private extension MainView {
    var isLaunchReady: Bool {
        isRevealed && launchScreen != nil
    }

    var hasSidebar: Bool {
        Self.hasSidebar(horizontalSizeClass)
    }

    var tabErrorCounts: [Int] {
        [
            home.errorNotice.count,
            records.errorNotice.count,
            review.errorNotice.count,
            assets.errorNotice.count
        ]
    }
}

private extension MainView {
    func replaceNotices(with source: NoticeSource) {
        if source != .entry {
            notice.clear()
        }

        if source != .deletion {
            undo.deletion = nil
        }

        if source != .undoError {
            undo.errorNotice.clear()
        }

        if source != .tab {
            noticeRound += 1
        }
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        let _ = try? database.insertDefaultsIfEmpty(at: Date())

        MainView(
            database: database,
            today: LocalDate(Date(), in: .current)
        )
    }
}

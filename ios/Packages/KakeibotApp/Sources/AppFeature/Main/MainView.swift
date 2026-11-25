import Core
import DesignSystem
import FeatureModels
import Features
import Store
import StoreKit
import SwiftUI

struct MainView: View {
    @State var model: MainModel
    @State var home: HomeModel
    @State var records: RecordsModel
    @State var review: ReviewModel
    @State var assets: AssetsModel
    @State var setup: SetupModel
    @State var appIcon = AppIconListModel()
    @State var notice: EntryNoticeModel
    @State var appReview: AppReviewModel
    @State var undo: DeletionUndo
    @State var orderMenuAnchor: CGRect?
    @State var observationRound = 0

    @Environment(\.requestReview) var requestReview

    @State private var isWarmingEntry = true
    @State private var foreground = AppForegroundReturn()
    @State private var noticeRound = 0

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase

    let parts: ScreenParts
    let today: LocalDate
    let route: PlannedNotification.Route?
    let onRouteOpened: () -> Void

    private let isRevealed: Bool
    private let onLoad: () -> Void

    init(
        database: AppDatabase,
        clock: ScreenClock,
        today: LocalDate,
        route: PlannedNotification.Route? = nil,
        isRevealed: Bool = true,
        onRouteOpened: @escaping () -> Void = {},
        onLoad: @escaping () -> Void = {}
    ) {
        let parts = ScreenParts(database: database, clock: clock)

        _model = State(
            initialValue: MainModel(
                parts: parts,
                today: today
            )
        )

        _home = State(
            initialValue: HomeModel(
                parts: parts,
                today: today
            )
        )

        _records = State(
            initialValue: RecordsModel(
                parts: parts,
                today: today
            )
        )

        _review = State(
            initialValue: ReviewModel(
                parts: parts,
                today: today
            )
        )

        _assets = State(
            initialValue: AssetsModel(
                parts: parts,
                today: today
            )
        )

        _setup = State(
            initialValue: SetupModel(parts: parts, newsVersion: WhatsNewRelease.latestVersion)
        )

        _notice = State(initialValue: EntryNoticeModel(parts: parts))

        _appReview = State(initialValue: AppReviewModel(database: database, clock: clock))

        _undo = State(initialValue: DeletionUndo(parts: parts))

        self.parts = parts
        self.today = today
        self.route = route
        self.isRevealed = isRevealed
        self.onRouteOpened = onRouteOpened
        self.onLoad = onLoad
    }

    var body: some View {
        ZStack {
            homeTab

            recordsTab

            reviewTab

            assetsTab
        }
        .environment(\.noticeRound, noticeRound)
        .overlay(alignment: .leading) {
            if hasSidebar {
                tabBar
            }
        }
        .overlay(alignment: .bottom) {
            if !hasSidebar {
                tabBar
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

            MainOutcomeSignal {
                home.state.outcome
            } onOutcome: { change in
                show(change)
            }

            MainOutcomeSignal {
                appReview.state.outcome
            } onOutcome: {
                requestReview()
            }
        }
        .sheet(item: Bindable(model.state).sheet) {
            model.prepareDraft()
        } content: { sheet in
            sheetContent(for: sheet)
                .presentationSizing(.tallForm)
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
            await model.state.draft.load()
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
        .onChange(of: model.state.sheet) { _, sheet in
            markOpened(sheet)
        }
        .onChange(of: today) { _, today in
            home.state.today = today
            records.state.today = today
            review.state.today = today
            assets.setToday(today)
            model.setToday(today)
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
    var tabBar: some View {
        MainTabBar(
            state: model.state,
            hasSidebar: hasSidebar,
            isAddHinted: !setup.input.isEntryOpened
        ) {
            model.state.sheet = .new
        }
    }

    var notices: some View {
        let noticeAbove = Self.noticeAbove(hasSidebar: hasSidebar)
        let noticeBottom = Self.noticeBottom(hasSidebar: hasSidebar)

        return Color.clear
            .padding(.leading, Self.noticeLeading(hasSidebar: hasSidebar))
            .entryNotice(notice, above: noticeAbove)
            .deletionNotice(Bindable(undo.state).deletion, bottom: noticeBottom) { deletion in
                undo.perform {
                    await $0.restore(deletion)
                }
            }
            .errorBanner(undo.state.errorNotice, bottom: noticeBottom) {
                undo.state.errorNotice.clear()
            }
            .onChange(of: notice.state.notice) { _, new in
                if new != nil {
                    replaceNotices(with: .entry)
                }
            }
            .onChange(of: undo.state.deletion) { _, new in
                if new != nil {
                    replaceNotices(with: .deletion)
                }
            }
            .onChange(of: undo.state.errorNotice.count) {
                replaceNotices(with: .undoError)
            }
            .onChange(of: tabErrorCounts) {
                replaceNotices(with: .tab)
            }
    }

    var entryWarmup: some View {
        EntrySheet(model: model.state.draft)
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
        isRevealed && model.input.launchScreen != nil
    }

    var hasSidebar: Bool {
        Self.hasSidebar(horizontalSizeClass)
    }

    var tabErrorCounts: [Int] {
        [
            home.state.errorNotice.count,
            records.state.errorNotice.count,
            review.state.errorNotice.count,
            assets.state.errorNotice.count
        ]
    }
}

private extension MainView {
    func replaceNotices(with source: NoticeSource) {
        if source != .entry {
            notice.clear()
        }

        if source != .deletion {
            undo.state.deletion = nil
        }

        if source != .undoError {
            undo.state.errorNotice.clear()
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
            clock: .system,
            today: LocalDate(Date(), in: .current)
        )
    }
}

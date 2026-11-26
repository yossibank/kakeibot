import Core
import DesignSystem
import FeatureModels
import Features
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
    @State var layout = Layout()

    @Environment(\.requestReview) var requestReview

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase

    let parts: ScreenParts
    let today: LocalDate
    let route: PlannedNotification.Route?
    let onRouteOpened: () -> Void

    private let isRevealed: Bool
    private let onLoad: () -> Void

    init(
        parts: ScreenParts,
        today: LocalDate,
        route: PlannedNotification.Route? = nil,
        isRevealed: Bool = true,
        onRouteOpened: @escaping () -> Void = {},
        onLoad: @escaping () -> Void = {}
    ) {
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

        _appReview = State(initialValue: AppReviewModel(parts: parts))

        self.parts = parts
        self.today = today
        self.route = route
        self.isRevealed = isRevealed
        self.onRouteOpened = onRouteOpened
        self.onLoad = onLoad
    }

    var body: some View {
        runningTabs
            .onChange(of: scenePhase) { _, phase in
                model.state.changeScene(to: ForegroundReturn.Phase(phase))
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

extension MainView {
    struct Layout {
        var orderMenuAnchor: CGRect?
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
    var tabStack: some View {
        ZStack {
            homeTab

            recordsTab

            reviewTab

            assetsTab
        }
        .environment(\.noticeRound, model.state.noticeRound)
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
            if let orderMenuAnchor = layout.orderMenuAnchor {
                HomeTemplateOrderMenu(
                    selection: templateOrderBinding,
                    anchor: orderMenuAnchor
                ) {
                    withAnimation(.snappy(duration: 0.2)) {
                        layout.orderMenuAnchor = nil
                    }
                }
                .transition(.opacity)
            }
        }
        .overlay {
            notices
        }
    }

    @ViewBuilder
    var signals: some View {
        if model.state.isWarmingEntry {
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

    var runningTabs: some View {
        tabStack
            .background {
                signals
            }
            .sheet(item: Bindable(model.state).sheet) {
                model.prepareDraft()
            } content: { sheet in
                sheetContent(for: sheet)
                    .presentationSizing(.tallForm)
            }
            .task {
                await observe()
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
    }

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

        let undo = model.state.undo

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
                await model.warmUpEntry()
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

    func replaceNotices(with source: NoticeSource) {
        if source != .entry {
            notice.clear()
        }

        if source != .deletion {
            model.state.undo.state.deletion = nil
        }

        if source != .undoError {
            model.state.undo.state.errorNotice.clear()
        }

        if source != .tab {
            model.state.hideTabNotices()
        }
    }
}

#Preview {
    if let parts = ScreenParts.preview() {
        MainView(
            parts: parts,
            today: LocalDate(Date(), in: .current)
        )
    }
}

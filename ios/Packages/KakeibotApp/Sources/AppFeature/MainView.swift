import Core
import DesignSystem
import Features
import Foundation
import Store
import SwiftUI

struct MainView: View {
    @State private var tab: MainTab = .home
    @State private var sheet: Sheet?
    @State private var home: HomeModel
    @State private var records: RecordsModel
    @State private var review: ReviewModel
    @State private var assets: AssetsModel
    @State private var draft: EntryModel
    @State private var notice: EntryNoticeModel
    @State private var isWarmingEntry = true
    @State private var orderMenuAnchor: CGRect?

    private let database: AppDatabase
    private let today: LocalDate
    private let route: PlannedNotification.Route?
    private let onRouteOpened: () -> Void

    init(
        database: AppDatabase,
        today: LocalDate,
        route: PlannedNotification.Route? = nil,
        onRouteOpened: @escaping () -> Void = {}
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

        _draft = State(
            initialValue: EntryModel(
                database: database,
                date: today
            )
        )

        _notice = State(initialValue: EntryNoticeModel(database: database))
        self.database = database
        self.today = today
        self.route = route
        self.onRouteOpened = onRouteOpened
    }

    var body: some View {
        TabView(selection: $tab) {
            Tab(value: MainTab.home) {
                HomeView(
                    model: home,
                    onOpenEntry: { id in
                        sheet = .edit(id)
                    },
                    onShowRecords: {
                        tab = .records
                    },
                    onOpenSettings: {
                        sheet = .settings
                    },
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
                        sheet = .recurrings
                    }
                )
                .tabContent()
            }

            Tab(value: MainTab.records) {
                RecordsView(
                    model: records,
                    onOpenEntry: { id in
                        sheet = .edit(id)
                    },
                    onDelete: { id in
                        Task {
                            await notice.delete(id, in: records.list)
                        }
                    },
                    onAddEntry: { date in
                        draft.date = date
                        sheet = .new
                    }
                )
                .tabContent()
            }

            Tab(value: MainTab.review) {
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
                    }
                )
                .tabContent()
            }

            Tab(value: MainTab.assets) {
                AssetsView(
                    model: assets,
                    onTransfer: {
                        sheet = .transfer
                    },
                    onOpenWallet: { id in
                        sheet = .wallet(id)
                    }
                )
                .tabContent()
            }
        }
        .overlay(alignment: .bottom) {
            FloatingTabBar(
                selection: $tab,
                items: Self.tabItems
            ) {
                sheet = .new
            }
        }
        .overlay {
            if let orderMenuAnchor {
                TemplateOrderMenu(
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
        .entryNotice(notice, above: FloatingTabBar<Int>.height)
        .background {
            if isWarmingEntry {
                entryWarmup
            }
        }
        .preferredColorScheme(.dark)
        .sheet(item: $sheet, onDismiss: prepareDraft) { sheet in
            sheetContent(for: sheet)
        }
        .task {
            await home.run()
        }
        .task {
            await records.run()
        }
        .task {
            await review.run()
        }
        .task {
            await assets.run()
        }
        .task {
            await draft.load()
        }
        .task {
            await openLaunchScreen()
        }
        .onChange(of: route, initial: true) { _, route in
            if let route {
                open(route)
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

private extension MainView {
    @ViewBuilder
    func sheetContent(for sheet: Sheet) -> some View {
        switch sheet {
        case .new:
            EntrySheet(model: draft, onChange: notice.show)
        case let .edit(id):
            EntrySheet(
                model: EntryModel(
                    database: database,
                    editing: id,
                    date: today
                ),
                onChange: notice.show
            )
        case .settings:
            SettingsSheet(
                database: database,
                today: today
            )
        case let .template(template):
            EntrySheet(
                model: EntryModel(
                    database: database,
                    date: today,
                    template: template
                ),
                onChange: notice.show
            )
        case .transfer:
            EntrySheet(
                model: EntryModel(
                    database: database,
                    date: today,
                    type: .transfer
                ),
                onChange: notice.show
            )
        case .templates:
            TemplateShelfSheet(
                model: home,
                database: database,
                onUse: useTemplate
            )
        case .newTemplate:
            TemplateEditSheet(
                model: TemplateEditModel(
                    database: database,
                    type: home.templateType
                )
            )
        case let .recurring(id):
            RecurringEditSheet(
                model: RecurringEditModel(
                    database: database,
                    today: today,
                    editing: id
                )
            )
        case .recurrings:
            NavigationStack {
                RecurringListView(
                    model: RecurringListModel(
                        database: database,
                        today: today
                    )
                )
            }
        case let .wallet(id):
            WalletEditSheet(
                model: WalletEditModel(
                    database: database,
                    editing: id
                )
            )
        }
    }
}

private extension MainView {
    enum MainTab: Hashable {
        case home
        case records
        case review
        case assets
    }

    enum Sheet: Hashable, Identifiable {
        case new
        case edit(Entry.ID)
        case settings
        case template(EntryTemplate)
        case newTemplate
        case templates
        case transfer
        case wallet(Wallet.ID)
        case recurring(Recurring.ID)
        case recurrings

        var id: Self {
            self
        }
    }

    static let tabItems: [FloatingTabBar<MainTab>.Item] = [
        .init("ホーム", systemImage: "house", value: .home),
        .init("記録", systemImage: "calendar", value: .records),
        .init("振り返り", systemImage: "chart.pie", value: .review),
        .init("資産", systemImage: "building.columns", value: .assets)
    ]

    static let warmupDuration: Duration = .milliseconds(500)
    static let sheetCloseDuration: Duration = .milliseconds(600)
}

private extension MainView {
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
        guard await (try? database.setting(.launchScreen)) == .entry else {
            return
        }

        guard route == nil else {
            return
        }

        sheet = .new
    }

    func open(_ route: PlannedNotification.Route) {
        onRouteOpened()

        Task {
            if sheet != nil {
                sheet = nil
                try? await Task.sleep(for: Self.sheetCloseDuration)
            }

            switch route {
            case let .entry(date):
                tab = .home
                draft.date = date
                sheet = .new
            case let .recurring(id):
                sheet = .recurring(id)
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

private extension View {
    func tabContent() -> some View {
        toolbar(.hidden, for: .tabBar)
            .safeAreaPadding(.bottom, FloatingTabBar<Int>.height)
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

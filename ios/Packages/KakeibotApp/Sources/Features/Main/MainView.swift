import Core
import DesignSystem
import Foundation
import Store
import SwiftUI

public struct MainView: View {
    @State private var tab: MainTab = .home
    @State private var sheet: Sheet?
    @State private var home: HomeModel
    @State private var records: RecordsModel
    @State private var assets: AssetsModel
    @State private var draft: EntryModel
    @State private var notice: EntryNoticeModel
    @State private var isWarmingEntry = true
    @State private var orderMenuAnchor: CGRect?

    private let database: AppDatabase

    public init(database: AppDatabase) {
        let today = LocalDate(Date(), in: .current)

        _home = State(
            initialValue: HomeModel(
                database: database,
                today: today
            )
        )

        _records = State(
            initialValue: RecordsModel(
                database: database,
                month: today.yearMonth
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
    }

    public var body: some View {
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
                    }
                )
                .tabContent()
            }

            Tab(value: MainTab.review) {
                ComingSoonView(title: "振り返り", systemImage: "chart.pie")
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
                    selection: $home.templateOrder,
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
            await home.observe()
        }
        .task {
            await home.observeTemplates()
        }
        .task {
            await home.observeBudgets()
        }
        .task {
            await observeMonthStartDay()
        }
        .task {
            await records.observe()
        }
        .task {
            await assets.observe()
        }
        .task {
            await draft.load()
        }
        .onReceive(
            NotificationCenter.default.publisher(for: .NSCalendarDayChanged)
        ) { _ in
            home.today = LocalDate(Date(), in: .current)
            assets.today = home.today
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
                    date: home.today
                ),
                onChange: notice.show
            )
        case .settings:
            SettingsSheet(database: database)
        case let .template(template):
            EntrySheet(
                model: EntryModel(
                    database: database,
                    date: home.today,
                    template: template
                ),
                onChange: notice.show
            )
        case .transfer:
            EntrySheet(
                model: EntryModel(
                    database: database,
                    date: home.today,
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

    enum Sheet: Identifiable {
        case new
        case edit(Entry.ID)
        case settings
        case template(EntryTemplate)
        case newTemplate
        case templates
        case transfer
        case wallet(Wallet.ID)

        var id: String {
            switch self {
            case .new: "new"
            case let .edit(id): "edit-\(id)"
            case .settings: "settings"
            case let .template(template): "template-\(template.id)"
            case .newTemplate: "new-template"
            case .templates: "templates"
            case .transfer: "transfer"
            case let .wallet(id): "wallet-\(id)"
            }
        }
    }

    static let tabItems: [FloatingTabBar<MainTab>.Item] = [
        .init("ホーム", systemImage: "house", value: .home),
        .init("記録", systemImage: "calendar", value: .records),
        .init("振り返り", systemImage: "chart.pie", value: .review),
        .init("資産", systemImage: "building.columns", value: .assets)
    ]
}

private extension MainView {
    var entryWarmup: some View {
        EntrySheet(model: draft)
            .opacity(0)
            .allowsHitTesting(false)
            .task {
                try? await Task.sleep(for: .milliseconds(500))
                isWarmingEntry = false
            }
    }
}

private extension MainView {
    func observeMonthStartDay() async {
        do {
            for try await startDay in database.monthStartDayUpdates() {
                home.monthStartDay = startDay
                assets.monthStartDay = startDay
                records.setMonthStartDay(startDay, today: home.today)
            }
        } catch {
            return
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
        let model = EntryModel(database: database, date: home.today)
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
        MainView(database: database)
    }
}

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
    @State private var isWarmingEntry = true

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
                    onOpenTemplate: { template in
                        sheet = .template(template)
                    },
                    onAddTemplate: {
                        sheet = .newTemplate
                    }
                )
                .tabContent()
            }

            Tab(value: MainTab.records) {
                RecordsView(model: records) { id in
                    sheet = .edit(id)
                }
                .tabContent()
            }

            Tab(value: MainTab.review) {
                ComingSoonView(title: "振り返り", systemImage: "chart.pie")
                    .tabContent()
            }

            Tab(value: MainTab.assets) {
                AssetsView(model: assets) {
                    sheet = .transfer
                }
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
            EntrySheet(model: draft)
        case let .edit(id):
            EntrySheet(
                model: EntryModel(
                    database: database,
                    editing: id,
                    date: home.today
                )
            )
        case .settings:
            SettingsSheet(database: database)
        case let .template(template):
            EntrySheet(
                model: EntryModel(
                    database: database,
                    date: home.today,
                    template: template
                )
            )
        case .transfer:
            EntrySheet(
                model: EntryModel(
                    database: database,
                    date: home.today,
                    type: .transfer
                )
            )
        case .newTemplate:
            TemplateEditSheet(
                model: TemplateEditModel(
                    database: database,
                    type: home.templateType
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
        case transfer

        var id: String {
            switch self {
            case .new: "new"
            case let .edit(id): "edit-\(id)"
            case .settings: "settings"
            case let .template(template): "template-\(template.id)"
            case .newTemplate: "new-template"
            case .transfer: "transfer"
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

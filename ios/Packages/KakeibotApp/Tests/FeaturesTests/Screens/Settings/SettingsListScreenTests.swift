import Core
@testable import Features
import Store
import SwiftUI
import Testing

@MainActor
struct SettingsListScreenTests {
    static let limit = 28

    @Test
    func listScreenTypesStayShallow() throws {
        let database = try AppDatabase.inMemory()
        let now = Date()
        let today = LocalDate(now, in: .current)

        try database.insertDefaultsIfEmpty(at: now)

        let recurring = RecurringListModel(database: database, clock: .system, today: today)

        let depths = [
            "CategoryListView": SettingsMenuSheetTests
                .depth(of: CategoryListView(database: database).body),
            "StampListView": SettingsMenuSheetTests
                .depth(of: StampListView(database: database).body),
            "RewardRuleListView": SettingsMenuSheetTests
                .depth(of: RewardRuleListView(database: database).body),
            "WalletListView": SettingsMenuSheetTests
                .depth(of: WalletListView(database: database).body),
            "RecurringListView": SettingsMenuSheetTests
                .depth(of: RecurringListView(model: recurring).body),
            "TemplateListView": SettingsMenuSheetTests
                .depth(of: TemplateListView(database: database).body)
        ]

        for (name, depth) in depths.sorted(by: { $0.key < $1.key }) {
            #expect(depth <= Self.limit, "\(name): \(depth)")
        }
    }
}

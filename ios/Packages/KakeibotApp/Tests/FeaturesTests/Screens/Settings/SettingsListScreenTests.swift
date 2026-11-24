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

        let depths = [
            "CategoryListView": SettingsMenuSheetTests
                .depth(of: CategoryListView(parts: .system(database)).body),
            "StampListView": SettingsMenuSheetTests
                .depth(of: StampListView(parts: .system(database)).body),
            "RewardRuleListView": SettingsMenuSheetTests
                .depth(of: RewardRuleListView(parts: .system(database)).body),
            "WalletListView": SettingsMenuSheetTests
                .depth(of: WalletListView(parts: .system(database)).body),
            "RecurringListView": SettingsMenuSheetTests
                .depth(of: RecurringListView(
                    board: RecurringBoard(parts: .system(database), today: today)
                ).body),
            "TemplateListView": SettingsMenuSheetTests
                .depth(of: TemplateListView(parts: .system(database)).body)
        ]

        for (name, depth) in depths.sorted(by: { $0.key < $1.key }) {
            #expect(depth <= Self.limit, "\(name): \(depth)")
        }
    }
}

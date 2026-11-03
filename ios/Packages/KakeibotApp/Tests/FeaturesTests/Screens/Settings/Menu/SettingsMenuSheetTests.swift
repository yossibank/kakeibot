import Core
@testable import Features
import Store
import SwiftUI
import Testing

@MainActor
struct SettingsMenuSheetTests {
    static let limit = 14

    @Test
    func sectionTypesStayShallow() throws {
        let database = try AppDatabase.inMemory()
        let now = Date()

        try database.insertDefaultsIfEmpty(at: now)

        let sheet = SettingsMenuSheet(
            database: database,
            today: LocalDate(now, in: .current),
            appIcon: AppIconListModel()
        )

        let depths = [
            "recordSection": Self.depth(of: sheet.recordSection),
            "budgetSection": Self.depth(of: sheet.budgetSection),
            "funSection": Self.depth(of: sheet.funSection),
            "homeSection": Self.depth(of: sheet.homeSection),
            "lookSection": Self.depth(of: sheet.lookSection),
            "dataSection": Self.depth(of: sheet.dataSection),
            "aboutSection": Self.depth(of: sheet.aboutSection)
        ]

        for (name, depth) in depths.sorted(by: { $0.key < $1.key }) {
            #expect(depth <= Self.limit, "\(name): \(depth)")
        }
    }
}

extension SettingsMenuSheetTests {
    static func depth(of value: some Any) -> Int {
        var current = 0
        var deepest = 0

        for character in _typeName(type(of: value)) {
            switch character {
            case "<", "(":
                current += 1
                deepest = max(deepest, current)

            case ">", ")":
                current -= 1

            default:
                break
            }
        }

        return deepest
    }
}

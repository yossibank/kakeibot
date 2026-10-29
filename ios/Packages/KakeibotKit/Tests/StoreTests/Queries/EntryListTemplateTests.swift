import Core
import Foundation
import Store
import Testing

struct EntryListTemplateTests {
    @Test
    func ordersByNameInJapanese() throws {
        let today = try #require(LocalDate("2026-10-17"))
        let names = ["ｂ", "10 円", "あ", "A", "2 円"]

        let list = EntryList(
            days: [],
            categories: [:],
            tags: [:],
            wallets: [:],
            icons: [:]
        )

        let templates = names.enumerated().map { order, name in
            Self.template(name, sortOrder: order)
        }

        let ordered = list.ordered(templates, by: .name, today: today)

        #expect(ordered.map(\.name) == ["2 円", "10 円", "A", "ｂ", "あ"])
    }
}

private extension EntryListTemplateTests {
    static func template(
        _ name: String,
        sortOrder: Int
    ) -> EntryTemplate {
        let now = Date(timeIntervalSince1970: 1_791_000_000)

        return EntryTemplate(
            name: name,
            type: .expense,
            amount: nil,
            categoryId: EntryCategory.ID(),
            walletId: Wallet.ID(),
            sortOrder: sortOrder,
            createdAt: now,
            updatedAt: now
        )
    }
}

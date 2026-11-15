import Core
@testable import Features
import Foundation
import Store
import Testing

struct EntryListFilterTests {
    @Test
    func listsSharedCategoryOnceByName() {
        let shared = Wallet.ID()

        let list = list([
            category(.expense, "食費"),
            category(.expense, "食費", in: shared),
            category(.income, "給与"),
            category(.income, "給与", in: shared)
        ])

        let names = list.filterCategories.map { "\($0.kind)-\($0.name)" }
        #expect(names == ["expense-食費", "income-給与"])
    }

    @Test
    func keepsSharedEntryOfSameCategory() throws {
        let shared = Wallet.ID()
        let own = category(.expense, "食費")
        let copy = category(.expense, "食費", in: shared)
        let list = list([own, copy])
        let filter = EntryFilter(categoryIds: [own.id])

        let widened = list.widened(filter)

        #expect(try widened.includes(entry(copy.id, in: shared)))
        #expect(try !widened.includes(entry(category(.income, "食費").id, in: shared)))
    }

    @Test
    func keepsSharedEntryOfSameTag() throws {
        let shared = Wallet.ID()
        let own = category(.expense, "食費")
        let copy = category(.expense, "食費", in: shared)
        let lunch = tag("昼食", of: own.id)
        let copied = tag("昼食", of: copy.id)
        let dinner = tag("夕食", of: copy.id)
        let list = list([own, copy], tags: [lunch, copied, dinner])
        let filter = EntryFilter(tagIds: [lunch.id])

        let widened = list.widened(filter)

        #expect(try widened.includes(entry(copy.id, tag: copied.id, in: shared)))
        #expect(try !widened.includes(entry(copy.id, tag: dinner.id, in: shared)))
    }
}

extension EntryListFilterTests {
    var now: Date {
        Date(timeIntervalSince1970: 1_791_000_000)
    }

    func category(
        _ kind: EntryCategory.Kind,
        _ name: String,
        in walletId: Wallet.ID? = nil
    ) -> EntryCategory {
        EntryCategory(
            kind: kind,
            name: name,
            iconId: Icon.ID(),
            sortOrder: 0,
            walletId: walletId,
            createdAt: now,
            updatedAt: now
        )
    }

    func tag(
        _ name: String,
        of categoryId: EntryCategory.ID
    ) -> EntryTag {
        EntryTag(
            categoryId: categoryId,
            name: name,
            sortOrder: 0,
            createdAt: now,
            updatedAt: now
        )
    }

    func entry(
        _ categoryId: EntryCategory.ID,
        tag tagId: EntryTag.ID? = nil,
        in walletId: Wallet.ID
    ) throws -> Entry {
        let date = try #require(LocalDate("2027-01-20"))

        return Entry(
            type: .expense,
            amount: 1000,
            date: date,
            categoryId: categoryId,
            tagId: tagId,
            walletId: walletId,
            createdAt: now,
            updatedAt: now
        )
    }

    func list(
        _ categories: [EntryCategory],
        tags: [EntryTag] = []
    ) -> EntryList {
        let categoriesByID = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
        let tagsByID = Dictionary(uniqueKeysWithValues: tags.map { ($0.id, $0) })

        return EntryList(
            days: [],
            categories: categoriesByID,
            tags: tagsByID,
            wallets: [:],
            icons: [:]
        )
    }
}

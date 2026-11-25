import Core
@testable import FeatureModels
@testable import Features
import Foundation
import Store
import Testing

extension EntryRowItemTests {
    @Test
    func showsTagNameOfEntry() throws {
        let setup = try Setup()
        var entry = try setup.entry(billMonth: "2027-02")
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        let categoryId = try #require(entry.categoryId)

        let tag = EntryTag(
            categoryId: categoryId,
            name: "昼ごはん",
            sortOrder: 0,
            createdAt: now,
            updatedAt: now
        )

        let list = EntryList(
            days: [],
            categories: [:],
            tags: [tag.id: tag],
            wallets: [setup.card.id: setup.card],
            icons: [:],
            cardBills: [setup.bill]
        )

        let plain = EntryRowItem(entry, in: list)

        entry.tagId = tag.id

        let tagged = EntryRowItem(entry, in: list)

        #expect(plain.tag == nil)
        #expect(tagged.tag == "昼ごはん")
    }
}

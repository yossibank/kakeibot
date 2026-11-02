import Core
import Foundation
import Testing

struct ReceiptReadingTests {
    @Test(arguments: try readingCases)
    func readsLines(fixture: ReadingCase) {
        let reading = ReceiptReading(lines: fixture.lines)

        #expect(reading.store == fixture.store)
        #expect(reading.date == fixture.date)
        #expect(reading.total == fixture.total)
        #expect(reading.items == fixture.items.map(\.draft))
    }

    @Test
    func measuresDifferenceFromTotal() {
        let items = [
            EntryItem.Draft(name: "牛乳", amount: 396),
            EntryItem.Draft(name: "パン", amount: 220)
        ]

        let reading = ReceiptReading(total: 646, items: items)
        let unread = ReceiptReading(items: items)

        #expect(reading.itemTotal == 616)
        #expect(reading.difference == 30)
        #expect(unread.difference == nil)
    }

    @Test
    func renamesItemsByRememberedNames() {
        let reading = ReceiptReading(
            store: "スーパー青葉",
            items: [
                EntryItem.Draft(name: "ギユウニユウ", quantity: 2, amount: 396),
                EntryItem.Draft(name: "食パン", amount: 220)
            ]
        )

        let renamed = reading.renamed(by: ["ギユウニユウ": "牛乳"])

        #expect(renamed.items.map(\.name) == ["牛乳", "食パン"])
        #expect(renamed.items.map(\.quantity) == [2, 1])
        #expect(renamed.store == "スーパー青葉")
    }

    @Test
    func isEmptyOnlyWhenNothingWasRead() {
        #expect(ReceiptReading().isEmpty)
        #expect(!ReceiptReading(total: 911).isEmpty)
        #expect(!ReceiptReading(lines: ["スーパー青葉"]).isEmpty)
    }
}

extension ReceiptReadingTests {
    struct ReadingCase: Decodable, Sendable, CustomTestStringConvertible {
        let summary: String
        let lines: [String]
        let store: String?
        let date: LocalDate?
        let total: Int?
        let items: [ItemCase]

        var testDescription: String {
            summary
        }
    }

    struct ItemCase: Decodable, Sendable {
        let name: String
        let quantity: Int
        let amount: Int

        var draft: EntryItem.Draft {
            EntryItem.Draft(name: name, quantity: quantity, amount: amount)
        }
    }
}

private extension ReceiptReadingTests {
    static var readingCases: [ReadingCase] {
        get throws {
            try Fixture.cases("receipt/receipt-reading.json")
        }
    }
}

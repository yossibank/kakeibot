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

        let again = renamed.renamed(by: [:])

        #expect(renamed.items.map(\.name) == ["牛乳", "食パン"])
        #expect(renamed.items.map(\.readName) == ["ギユウニユウ", "食パン"])
        #expect(renamed.items.map(\.quantity) == [2, 1])
        #expect(renamed.store == "スーパー青葉")
        #expect(again.items.map(\.readName) == ["ギユウニユウ", "食パン"])
    }

    @Test(arguments: try mergingCases)
    func choosesItemsCloserToTotal(fixture: MergingCase) {
        let merged = fixture.rules.reading.merging(fixture.guessed.reading)

        #expect(merged.total == fixture.total)
        #expect(merged.items == fixture.items.map(\.draft))
        #expect(merged.taxIncluded == fixture.taxIncluded)
    }

    @Test
    func prefersStoreFromModelAndDateFromRules() throws {
        let ruleDate = try #require(LocalDate("2026-10-03"))
        let guessDate = try #require(LocalDate("2026-10-04"))

        let merged = ReceiptReading(store: "青葉", date: ruleDate)
            .merging(ReceiptReading(store: "スーパー青葉", date: guessDate))

        let filled = ReceiptReading(store: "青葉")
            .merging(ReceiptReading(date: guessDate))

        #expect(merged.store == "スーパー青葉")
        #expect(merged.date == ruleDate)
        #expect(filled.store == "青葉")
        #expect(filled.date == guessDate)
    }

    @Test
    func addsExclusiveTaxToItemTotal() {
        let reading = ReceiptReading(
            total: 650,
            items: [
                EntryItem.Draft(name: "牛乳", amount: 198, taxRate: .reduced),
                EntryItem.Draft(name: "洗剤", amount: 398, taxRate: .standard)
            ]
        )

        #expect(reading.itemTotal == 650)
        #expect(reading.difference == 0)
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
        let items: [ReceiptItemValue]

        var testDescription: String {
            summary
        }
    }

    struct MergingCase: Decodable, Sendable, CustomTestStringConvertible {
        let summary: String
        let rules: ReadingValue
        let guessed: ReadingValue
        let total: Int?
        let items: [ReceiptItemValue]
        let taxIncluded: Bool

        var testDescription: String {
            summary
        }
    }

    struct ReadingValue: Decodable, Sendable {
        let total: Int?
        let items: [ReceiptItemValue]

        var reading: ReceiptReading {
            ReceiptReading(total: total, items: items.map(\.draft))
        }
    }
}

private extension ReceiptReadingTests {
    static var readingCases: [ReadingCase] {
        get throws {
            try Fixture.cases("receipt/receipt-reading.json")
        }
    }

    static var mergingCases: [MergingCase] {
        get throws {
            try Fixture.cases("receipt/receipt-merging.json")
        }
    }
}

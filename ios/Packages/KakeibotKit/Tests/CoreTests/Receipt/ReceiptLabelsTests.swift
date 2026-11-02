import Core
import Foundation
import Testing

struct ReceiptLabelsTests {
    @Test(arguments: try labelCases)
    func readsLabeledLines(fixture: LabelCase) {
        let reading = ReceiptReading(lines: fixture.lines, labels: fixture.labels.labels)

        #expect(reading.store == fixture.store)
        #expect(reading.date == fixture.date)
        #expect(reading.total == fixture.total)
        #expect(reading.items == fixture.items.map(\.draft))
    }

    @Test
    func shiftsLinesOfLaterPages() {
        let first = ReceiptLabels(
            storeLine: 0,
            totalLine: nil,
            items: [ReceiptLabels.Item(line: 1)]
        )

        let second = ReceiptLabels(
            storeLine: 0,
            totalLine: 2,
            items: [ReceiptLabels.Item(line: 0, quantityLine: 1, discountLines: [2])]
        )

        let joined = first.appending(second.shifted(by: 3))

        #expect(joined.storeLine == 0)
        #expect(joined.totalLine == 5)
        #expect(joined.items.map(\.line) == [1, 3])
        #expect(joined.items.last?.quantityLine == 4)
        #expect(joined.items.last?.discountLines == [5])
    }
}

extension ReceiptLabelsTests {
    struct LabelCase: Decodable, Sendable, CustomTestStringConvertible {
        let summary: String
        let lines: [String]
        let labels: LabelsValue
        let store: String?
        let date: LocalDate?
        let total: Int?
        let items: [ReceiptItemValue]

        var testDescription: String {
            summary
        }
    }

    struct LabelsValue: Decodable, Sendable {
        let storeLine: Int?
        let dateLine: Int?
        let totalLine: Int?
        let items: [ItemLabelValue]

        var labels: ReceiptLabels {
            ReceiptLabels(
                storeLine: storeLine,
                dateLine: dateLine,
                totalLine: totalLine,
                items: items.map(\.item)
            )
        }
    }

    struct ItemLabelValue: Decodable, Sendable {
        let line: Int
        let quantityLine: Int?
        let discountLines: [Int]
        let taxRate: Int?

        var item: ReceiptLabels.Item {
            ReceiptLabels.Item(
                line: line,
                quantityLine: quantityLine,
                discountLines: discountLines,
                taxRate: taxRate.flatMap(EntryItem.TaxRate.init(rawValue:))
            )
        }
    }
}

struct ReceiptItemValue: Decodable, Sendable {
    let name: String
    let quantity: Int
    let amount: Int
    let taxRate: Int?

    var draft: EntryItem.Draft {
        EntryItem.Draft(
            name: name,
            quantity: quantity,
            amount: amount,
            taxRate: taxRate.flatMap(EntryItem.TaxRate.init(rawValue:))
        )
    }
}

private extension ReceiptLabelsTests {
    static var labelCases: [LabelCase] {
        get throws {
            try Fixture.cases("receipt/receipt-labels.json")
        }
    }
}

import Core
import Foundation
import Testing

struct ReceiptSuspectTests {
    @Test(arguments: try suspectCases)
    func picksSuspectItems(fixture: SuspectCase) {
        let items = fixture.items.map(\.draft)

        let suspects = ReceiptSuspect.indices(of: items, difference: fixture.difference)

        #expect(suspects == fixture.suspects)
    }
}

extension ReceiptSuspectTests {
    struct SuspectCase: Decodable, Sendable, CustomTestStringConvertible {
        let summary: String
        let items: [ItemValue]
        let difference: Int
        let suspects: [Int]

        var testDescription: String {
            summary
        }
    }

    struct ItemValue: Decodable, Sendable {
        let amount: Int
        let taxRate: Int?

        var draft: EntryItem.Draft {
            EntryItem.Draft(
                name: "品目",
                amount: amount,
                taxRate: taxRate.flatMap(EntryItem.TaxRate.init(rawValue:))
            )
        }
    }
}

private extension ReceiptSuspectTests {
    static var suspectCases: [SuspectCase] {
        get throws {
            try CoreFixture.cases("receipt/receipt-suspects.json")
        }
    }
}

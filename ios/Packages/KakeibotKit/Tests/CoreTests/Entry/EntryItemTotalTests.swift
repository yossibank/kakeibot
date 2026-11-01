import Core
import Testing

struct EntryItemTotalTests {
    @Test(arguments: try cases)
    func totalsItems(fixture: TotalCase) throws {
        let items = try fixture.items.map { item in
            try EntryItem.Draft(name: "品目", amount: item.amount, taxRate: Self.rate(item.taxRate))
        }

        let total = EntryItemTotal(items)
        let taxes = total.taxes.map { tax in
            Tax(rate: tax.rate.rawValue, base: tax.base, amount: tax.amount)
        }

        #expect(total.subtotal == fixture.subtotal)
        #expect(taxes == fixture.taxes)
        #expect(total.total == fixture.total)
    }
}

extension EntryItemTotalTests {
    struct TotalCase: Decodable, Sendable {
        let items: [Item]
        let subtotal: Int
        let taxes: [Tax]
        let total: Int
    }

    struct Item: Decodable, Sendable {
        let amount: Int
        let taxRate: Int?
    }

    struct Tax: Decodable, Equatable, Sendable {
        let rate: Int
        let base: Int
        let amount: Int
    }

    enum RateError: Error {
        case unknown(Int)
    }
}

private extension EntryItemTotalTests {
    static var cases: [TotalCase] {
        get throws {
            try Fixture.cases("entry/entry-item-total.json")
        }
    }

    static func rate(_ value: Int?) throws -> EntryItem.TaxRate? {
        guard let value else {
            return nil
        }

        guard let rate = EntryItem.TaxRate(rawValue: value) else {
            throw RateError.unknown(value)
        }

        return rate
    }
}

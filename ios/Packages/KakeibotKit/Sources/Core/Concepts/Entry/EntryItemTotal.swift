public struct EntryItemTotal: Hashable, Sendable {
    public let subtotal: Int
    public let taxes: [Tax]
    public let total: Int
    public let taxIncluded: Bool

    public init(
        _ items: [EntryItem.Draft],
        taxIncluded: Bool = false
    ) {
        let subtotal = items.reduce(0) { $0 + $1.amount }

        let taxes = EntryItem.TaxRate.allCases.compactMap { rate in
            Tax(rate: rate, items: items, taxIncluded: taxIncluded)
        }

        let tax = taxes.reduce(0) { $0 + $1.amount }

        self.subtotal = subtotal
        self.taxes = taxes
        self.total = taxIncluded ? subtotal : subtotal + tax
        self.taxIncluded = taxIncluded
    }
}

public extension EntryItemTotal {
    struct Tax: Hashable, Sendable {
        public let rate: EntryItem.TaxRate
        public let base: Int
        public let amount: Int
    }
}

private extension EntryItemTotal.Tax {
    init?(
        rate: EntryItem.TaxRate,
        items: [EntryItem.Draft],
        taxIncluded: Bool
    ) {
        let rated = items.filter { $0.taxRate == rate }

        guard !rated.isEmpty else {
            return nil
        }

        let base = rated.reduce(0) { $0 + $1.amount }

        let amount = taxIncluded
            ? Self.included(in: base, rate: rate.rawValue)
            : base * rate.rawValue / 100

        self.init(rate: rate, base: base, amount: amount)
    }

    static func included(
        in base: Int,
        rate: Int
    ) -> Int {
        let numerator = abs(base) * rate * 2 + 100 + rate
        let rounded = numerator / ((100 + rate) * 2)
        return base < 0 ? -rounded : rounded
    }
}

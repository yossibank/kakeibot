public struct EntryItemTotal: Hashable, Sendable {
    public let subtotal: Int
    public let taxes: [Tax]
    public let total: Int

    public init(_ items: [EntryItem.Draft]) {
        let subtotal = items.reduce(0) { $0 + $1.amount }

        let taxes = EntryItem.TaxRate.allCases.compactMap { rate in
            Tax(rate: rate, items: items)
        }

        let tax = taxes.reduce(0) { $0 + $1.amount }

        self.subtotal = subtotal
        self.taxes = taxes
        self.total = subtotal + tax
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
        items: [EntryItem.Draft]
    ) {
        let rated = items.filter { $0.taxRate == rate }

        guard !rated.isEmpty else {
            return nil
        }

        let base = rated.reduce(0) { $0 + $1.amount }

        self.init(rate: rate, base: base, amount: base * rate.rawValue / 100)
    }
}

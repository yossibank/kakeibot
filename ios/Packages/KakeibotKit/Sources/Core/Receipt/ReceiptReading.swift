import Foundation

public struct ReceiptReading: Hashable, Sendable {
    public var store: String?
    public var date: LocalDate?
    public var total: Int?
    public var items: [EntryItem.Draft]
    public var taxIncluded: Bool

    var includedIndices: Set<Int> = []
    var taxBases: [EntryItem.TaxRate: Int] = [:]

    public init(
        store: String? = nil,
        date: LocalDate? = nil,
        total: Int? = nil,
        items: [EntryItem.Draft] = [],
        taxIncluded: Bool = false
    ) {
        self.store = store
        self.date = date
        self.total = total
        self.items = items
        self.taxIncluded = taxIncluded
    }
}

public extension ReceiptReading {
    var itemTotal: Int {
        EntryItemTotal(items, taxIncluded: taxIncluded).total
    }

    var difference: Int? {
        total.map { $0 - itemTotal }
    }

    var isEmpty: Bool {
        store == nil && date == nil && total == nil && items.isEmpty
    }

    var isSettled: Bool {
        store != nil && !items.isEmpty && difference == 0
    }

    init(lines: [String]) {
        self.init()

        var builder = Builder()

        for text in lines {
            let line = ReceiptLine(text)

            if date == nil {
                self.date = line.date
            }

            switch line.kind {
            case .taxBase:
                builder.add(line)
            case let .total(amount) where total == nil:
                self.total = amount
            default:
                if total == nil {
                    builder.add(line)
                }
            }
        }

        self.store = builder.store
        self.items = builder.items
        self.total = total ?? builder.derivedTotal
        self.includedIndices = builder.includedIndices
        self.taxBases = builder.taxBases
    }

    func renamed(by names: [String: String]) -> ReceiptReading {
        var reading = self

        for index in reading.items.indices {
            let read = reading.items[index].readName ?? reading.items[index].name

            reading.items[index].readName = read
            reading.items[index].name = names[read] ?? reading.items[index].name
        }

        return reading
    }

    func settlingTax() -> ReceiptReading {
        guard items.contains(where: { $0.taxRate != nil }) else {
            let candidates = [
                taxed(included: false),
                rating(.standard).taxed(included: false),
                rating(.reduced).taxed(included: false)
            ]

            let settled = candidates.first { $0.itemTotal == total } ?? taxed(included: false)

            return settled.items.contains(where: { $0.taxRate != nil })
                ? settled
                : settled.ratedByBase()
        }

        let rated = rating(.standard)

        let candidates = [
            taxed(included: false),
            rated.taxed(included: false),
            rated.taxed(included: true)
        ]

        return candidates.first { $0.itemTotal == total } ?? untaxed()
    }

    func merging(_ guessed: ReceiptReading) -> ReceiptReading {
        let rules = settlingTax()
        let guessed = guessed.settlingTax()
        let prefersRules = guessed.items.isEmpty || rules.gap(to: guessed.total) < guessed
            .gap(to: rules.total)
        let chosen = prefersRules ? rules : guessed
        let other = prefersRules ? guessed : rules

        return ReceiptReading(
            store: guessed.store ?? store,
            date: date ?? guessed.date,
            total: chosen.total ?? other.total,
            items: chosen.items,
            taxIncluded: chosen.taxIncluded
        )
    }
}

private extension ReceiptReading {
    func taxed(included: Bool) -> ReceiptReading {
        var reading = self
        reading.taxIncluded = included
        return reading
    }

    func rating(
        _ rate: EntryItem.TaxRate,
        onlyUnmarked: Bool = true
    ) -> ReceiptReading {
        var reading = self

        for index in reading.items.indices where !includedIndices.contains(index) {
            if !onlyUnmarked || reading.items[index].taxRate == nil {
                reading.items[index].taxRate = rate
            }
        }

        return reading
    }

    func ratedByBase() -> ReceiptReading {
        let subtotal = items.reduce(0) { $0 + $1.amount }

        guard
            taxBases.count == 1,
            let (rate, base) = taxBases.first,
            base == subtotal
        else {
            return self
        }

        return rating(rate, onlyUnmarked: false).taxed(included: true)
    }

    func untaxed() -> ReceiptReading {
        var reading = taxed(included: false)

        for index in reading.items.indices {
            reading.items[index].taxRate = nil
        }

        return reading
    }

    func gap(to fallback: Int?) -> Int {
        guard let total = total ?? fallback else {
            return .max
        }

        return abs(total - itemTotal)
    }
}

extension EntryItem.Draft {
    mutating func apply(_ quantity: ReceiptLine.Quantity) {
        if amount == quantity.unit {
            amount = quantity.unit * quantity.count
        }

        self.quantity = quantity.count
    }
}

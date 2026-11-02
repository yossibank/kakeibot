import Foundation

public struct ReceiptReading: Hashable, Sendable {
    public var store: String?
    public var date: LocalDate?
    public var total: Int?
    public var items: [EntryItem.Draft]

    public init(
        store: String? = nil,
        date: LocalDate? = nil,
        total: Int? = nil,
        items: [EntryItem.Draft] = []
    ) {
        self.store = store
        self.date = date
        self.total = total
        self.items = items
    }
}

public extension ReceiptReading {
    var itemTotal: Int {
        EntryItemTotal(items).total
    }

    var difference: Int? {
        total.map { $0 - itemTotal }
    }

    var isEmpty: Bool {
        store == nil && date == nil && total == nil && items.isEmpty
    }

    init(lines: [String]) {
        self.init()

        var pendingQuantity: ReceiptLine.Quantity?
        var hasItem = false

        for text in lines {
            let line = ReceiptLine(text)

            if date == nil {
                self.date = line.date
            }

            guard total == nil else {
                continue
            }

            switch line.kind {
            case let .total(amount):
                self.total = amount

            case let .item(name, amount):
                var item = EntryItem.Draft(name: name, amount: amount)

                if let quantity = pendingQuantity {
                    item.apply(quantity)
                    pendingQuantity = nil
                }

                items.append(item)
                hasItem = true

            case let .quantity(quantity):
                if quantity.isUnitFirst || items.isEmpty {
                    pendingQuantity = quantity
                } else {
                    items[items.count - 1].apply(quantity)
                }

            case let .discount(amount):
                if !items.isEmpty {
                    items[items.count - 1].amount += amount
                }

            case let .text(name):
                if store == nil, !hasItem, line.date == nil {
                    self.store = name
                }

            case .skip:
                break
            }
        }
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
        guard
            items.contains(where: { $0.taxRate != nil }),
            itemTotal != total
        else {
            return self
        }

        var reading = self

        for index in reading.items.indices {
            reading.items[index].taxRate = nil
        }

        return reading
    }

    func merging(_ guessed: ReceiptReading) -> ReceiptReading {
        let guessed = guessed.settlingTax()
        let prefersRules = guessed.items.isEmpty || gap(to: guessed.total) < guessed.gap(to: total)
        let chosen = prefersRules ? self : guessed
        let other = prefersRules ? guessed : self

        return ReceiptReading(
            store: store ?? guessed.store,
            date: date ?? guessed.date,
            total: chosen.total ?? other.total,
            items: chosen.items
        )
    }
}

private extension ReceiptReading {
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

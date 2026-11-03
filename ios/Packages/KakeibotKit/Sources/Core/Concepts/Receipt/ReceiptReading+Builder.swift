extension ReceiptReading {
    struct Builder {
        private(set) var items: [EntryItem.Draft] = []
        private(set) var includedIndices: Set<Int> = []
        private(set) var taxBases: [EntryItem.TaxRate: Int] = [:]

        private var storeLines: [String] = []
        private var titleIndex: Int?
        private var hasDate = false
        private var pendingName: String?
        private var pendingReduced = false
        private var pendingQuantity: ReceiptLine.Quantity?
        private var subtotal: Int?
        private var discountsAfterSubtotal = 0
        private var exclusiveTax = 0
        private var isSummary = false
        private var isStopped = false
    }
}

extension ReceiptReading.Builder {
    var store: String? {
        let preferred = titleIndex.flatMap { index in
            storeLines.indices.contains(index) ? storeLines[index] : nil
        }

        return (preferred ?? storeLines.first).map(ReceiptLine.storeName)
    }

    var derivedTotal: Int? {
        subtotal.map { $0 + discountsAfterSubtotal + exclusiveTax }
    }

    mutating func add(_ line: ReceiptLine) {
        if line.date != nil {
            hasDate = true
        }

        if case let .taxBase(rate, amount) = line.kind {
            taxBases[rate] = amount
            isSummary = true

            return
        }

        guard !isStopped else {
            return
        }

        switch line.kind {
        case let .heading(isTitle):
            if isTitle, items.isEmpty, titleIndex == nil {
                titleIndex = storeLines.count
            }

        case let .code(isReduced):
            pendingReduced = isReduced
            pendingName = nil

        case let .text(text):
            if items.isEmpty, !hasDate, line.isStoreLike {
                storeLines.append(text)
            }

            pendingName = text

        case let .item(amount):
            addItem(amount)

        case let .quantity(quantity):
            if quantity.isUnitFirst || items.isEmpty {
                pendingQuantity = quantity
            } else if !isSummary {
                items[items.count - 1].apply(quantity)
            }

        case let .discount(name, amount):
            addDiscount(name: name, amount: amount)

        case let .subtotal(amount):
            subtotal = subtotal ?? amount
            isSummary = true

        case let .tax(amount, isExclusive):
            if isExclusive {
                exclusiveTax += amount
            }

            isSummary = true

        case .stop:
            isStopped = !items.isEmpty

        case .taxBase, .total, .skip:
            break
        }
    }
}

private extension ReceiptReading.Builder {
    var largestRate: EntryItem.TaxRate? {
        items.max { $0.amount < $1.amount }?.taxRate
    }

    mutating func addItem(_ amount: ReceiptLine.Amount) {
        guard !isSummary else {
            return
        }

        let name = ReceiptLine.itemName(amount.name.isEmpty ? pendingName ?? "" : amount.name)

        guard !name.isEmpty else {
            return
        }

        let isReduced = amount.isReduced || pendingReduced

        var item = EntryItem.Draft(
            name: name,
            quantity: amount.count,
            amount: amount.value,
            taxRate: amount.isIncluded ? nil : (isReduced ? .reduced : nil)
        )

        if let quantity = pendingQuantity {
            item.apply(quantity)
            pendingQuantity = nil
        }

        if amount.isIncluded {
            includedIndices.insert(items.count)
        }

        items.append(item)
        pendingName = nil
        pendingReduced = false
    }

    mutating func addDiscount(
        name: String,
        amount: Int
    ) {
        guard let last = items.last else {
            return
        }

        if !isSummary, abs(amount) < last.amount {
            items[items.count - 1].amount += amount
            return
        }

        if isSummary, subtotal != nil {
            discountsAfterSubtotal += amount
        }

        items.append(
            EntryItem.Draft(
                name: name.isEmpty ? "値引" : name,
                amount: amount,
                taxRate: largestRate
            )
        )
    }
}

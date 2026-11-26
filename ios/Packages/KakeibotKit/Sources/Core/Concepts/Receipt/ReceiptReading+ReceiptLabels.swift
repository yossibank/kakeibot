public extension ReceiptReading {
    init(
        lines: [String],
        labels: ReceiptLabels
    ) {
        self.init()

        let parsed = lines.map(ReceiptLine.init)
        let sorted = labels.items.sorted { $0.line < $1.line }
        let end = Self.end(of: parsed, after: sorted.first?.line, totalLine: labels.totalLine)
        var picker = LinePicker(lines: parsed)

        self.store = picker.line(labels.storeLine).flatMap { $0.isNamed
            ? ReceiptLine.storeName($0.text)
            : nil
        }

        self.date = picker.line(labels.dateLine)?.date
        self.total = picker.line(labels.totalLine).flatMap(Self.total)

        for label in sorted where label.line < end {
            addItem(of: label, in: labels, end: end, picker: &picker)
        }

        addDiscounts(of: labels, end: end, picker: &picker)
        addTaxBases(of: parsed)
    }
}

private extension ReceiptReading {
    static func end(
        of lines: [ReceiptLine],
        after first: Int?,
        totalLine: Int?
    ) -> Int {
        let start = (first ?? 0) + 1
        let ruled = lines.indices.dropFirst(start).first { lines[$0].isEnd }
        let answered = totalLine.flatMap { $0 >= start ? $0 : nil }
        return [ruled, answered].compactMap(\.self).min() ?? lines.count
    }

    static func total(of line: ReceiptLine) -> Int? {
        switch line.kind {
        case let .total(amount):
            amount > 0 ? amount : nil

        case .heading, .item, .skip:
            line.amount.flatMap { $0.value > 0 ? $0.value : nil }

        default:
            nil
        }
    }

    static func nameIndex(
        of label: ReceiptLabels.Item,
        in lines: [ReceiptLine],
        skipping labeled: Set<Int>
    ) -> Int? {
        let candidates = [label.nameLine, label.line - 1].compactMap(\.self)

        return candidates.first { index in
            (label.line - 2..<label.line).contains(index)
                && lines.indices.contains(index)
                && (index == label.nameLine || !labeled.contains(index))
                && lines[index].isNamed
        }
    }

    mutating func addItem(
        of label: ReceiptLabels.Item,
        in labels: ReceiptLabels,
        end: Int,
        picker: inout LinePicker
    ) {
        guard
            let amount = picker.take(label.line, where: \.isItemLike)?.amount
        else {
            return
        }

        let parsed = picker.lines

        let nameIndex = amount.name.isEmpty
            ? Self.nameIndex(of: label, in: parsed, skipping: labels.labeledLines)
            : label.line

        let name = nameIndex.map { index in
            ReceiptLine.itemName(index == label.line ? amount.name : parsed[index].text)
        } ?? ""

        guard ReceiptLine.isNameLike(name) else {
            return
        }

        let isReduced = amount.isReduced || picker.line(nameIndex.map { $0 - 1 })?
            .isReducedCode == true

        if amount.isIncluded {
            includedIndices.insert(items.count)
        }

        var item = EntryItem.Draft(
            name: name,
            quantity: amount.count,
            amount: amount.value,
            taxRate: amount.isIncluded ? nil : label.taxRate ?? (isReduced ? .reduced : nil)
        )

        if let quantity = picker.take(label.quantityLine, where: { $0.quantity != nil })?.quantity {
            item.apply(quantity)
        }

        for index in label.discountLines where index < end {
            if let discount = picker.take(index, where: \.isDiscountLike)?.amount {
                item.amount -= abs(discount.value)
            }
        }

        items.append(item)
    }

    mutating func addDiscounts(
        of labels: ReceiptLabels,
        end: Int,
        picker: inout LinePicker
    ) {
        let largestRate = items.max { $0.amount < $1.amount }?.taxRate

        for index in labels.discountLines.sorted() where index < end && !items.isEmpty {
            if let discount = picker.take(index, where: \.isDiscountLike)?.amount {
                let name = ReceiptLine.itemName(discount.name)

                items.append(
                    EntryItem.Draft(
                        name: name.isEmpty ? "値引" : name,
                        amount: -abs(discount.value),
                        taxRate: largestRate
                    )
                )
            }
        }
    }

    mutating func addTaxBases(of lines: [ReceiptLine]) {
        for parsedLine in lines {
            if case let .taxBase(rate, amount) = parsedLine.kind {
                taxBases[rate] = amount
            }
        }
    }
}

private struct LinePicker {
    let lines: [ReceiptLine]

    var used: Set<Int> = []
}

extension LinePicker {
    func line(_ index: Int?) -> ReceiptLine? {
        guard
            let index,
            lines.indices.contains(index)
        else {
            return nil
        }

        return lines[index]
    }

    mutating func take(
        _ index: Int?,
        where isValid: (ReceiptLine) -> Bool
    ) -> ReceiptLine? {
        guard
            let index,
            let found = line(index),
            isValid(found),
            used.insert(index).inserted
        else {
            return nil
        }

        return found
    }
}

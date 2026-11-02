import Foundation

public extension ReceiptReading {
    init(
        lines: [String],
        labels: ReceiptLabels
    ) {
        self.init()

        let parsed = lines.map(ReceiptLine.init)
        let labeled = labels.labeledLines
        var used = Set<Int>()

        func line(_ index: Int?) -> ReceiptLine? {
            guard
                let index,
                parsed.indices.contains(index)
            else {
                return nil
            }

            return parsed[index]
        }

        func take(_ index: Int?) -> ReceiptLine? {
            guard
                let index,
                parsed.indices.contains(index),
                used.insert(index).inserted
            else {
                return nil
            }

            return parsed[index]
        }

        let store = line(labels.storeLine)?.text ?? ""
        self.store = store.isEmpty ? nil : store
        self.date = line(labels.dateLine)?.date
        self.total = line(labels.totalLine)?.amount.flatMap { $0.value > 0 ? $0.value : nil }

        for label in labels.items.sorted(by: { $0.line < $1.line }) {
            guard
                let itemLine = take(label.line),
                let amount = itemLine.amount,
                amount.value > 0
            else {
                continue
            }

            let name = (amount.name.isEmpty
                ? Self.nameAbove(label.line, in: parsed, skipping: labeled)
                : amount.name)
                .trimmingCharacters(in: Self.taxMarks)

            guard !name.isEmpty else {
                continue
            }

            var item = EntryItem.Draft(
                name: name,
                amount: amount.value,
                taxRate: label.taxRate
            )

            if let quantity = take(label.quantityLine)?.quantity {
                item.apply(quantity)
            }

            for index in label.discountLines {
                if let discount = take(index)?.amount {
                    item.amount -= abs(discount.value)
                }
            }

            items.append(item)
        }
    }
}

private extension ReceiptReading {
    static let taxMarks = CharacterSet(charactersIn: "※*軽").union(.whitespaces)

    static func nameAbove(
        _ index: Int,
        in lines: [ReceiptLine],
        skipping labeled: Set<Int>
    ) -> String {
        let above = index - 1

        guard
            lines.indices.contains(above),
            !labeled.contains(above),
            lines[above].amount == nil,
            lines[above].date == nil
        else {
            return ""
        }

        return lines[above].text
    }
}

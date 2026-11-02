import Foundation

public enum ReceiptSuspect {
    public static func indices(
        of items: [EntryItem.Draft],
        difference: Int
    ) -> [Int] {
        guard difference != 0 else {
            return []
        }

        return items.indices.filter { index in
            let item = items[index]

            return isExtra(item, difference: difference) || isMisread(item, difference: difference)
        }
    }
}

private extension ReceiptSuspect {
    static func isExtra(
        _ item: EntryItem.Draft,
        difference: Int
    ) -> Bool {
        difference < 0 && item.amount == -difference
    }

    static func isMisread(
        _ item: EntryItem.Draft,
        difference: Int
    ) -> Bool {
        let fixed = item.amount + difference

        guard
            item.taxRate == nil,
            item.amount > 0,
            fixed > 0
        else {
            return false
        }

        let read = Array(String(item.amount))
        let right = Array(String(fixed))

        guard read.count == right.count else {
            return false
        }

        let changed = zip(read, right).filter { $0 != $1 }

        guard
            changed.count == 1,
            let pair = changed.first
        else {
            return false
        }

        return confusedDigits.contains([pair.0, pair.1])
    }
}

private extension ReceiptSuspect {
    static let confusedDigits: Set<Set<Character>> = [
        ["0", "6"],
        ["0", "8"],
        ["0", "9"],
        ["1", "7"],
        ["3", "8"],
        ["5", "6"],
        ["5", "8"],
        ["6", "8"],
        ["8", "9"]
    ]
}

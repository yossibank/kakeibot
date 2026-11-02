public struct ReceiptLabels: Hashable, Sendable {
    public var storeLine: Int?
    public var dateLine: Int?
    public var totalLine: Int?
    public var items: [Item]

    public init(
        storeLine: Int? = nil,
        dateLine: Int? = nil,
        totalLine: Int? = nil,
        items: [Item] = []
    ) {
        self.storeLine = storeLine
        self.dateLine = dateLine
        self.totalLine = totalLine
        self.items = items
    }
}

public extension ReceiptLabels {
    struct Item: Hashable, Sendable {
        public var line: Int
        public var quantityLine: Int?
        public var discountLines: [Int]
        public var taxRate: EntryItem.TaxRate?

        public init(
            line: Int,
            quantityLine: Int? = nil,
            discountLines: [Int] = [],
            taxRate: EntryItem.TaxRate? = nil
        ) {
            self.line = line
            self.quantityLine = quantityLine
            self.discountLines = discountLines
            self.taxRate = taxRate
        }
    }

    func shifted(by offset: Int) -> ReceiptLabels {
        ReceiptLabels(
            storeLine: storeLine.map { $0 + offset },
            dateLine: dateLine.map { $0 + offset },
            totalLine: totalLine.map { $0 + offset },
            items: items.map { item in
                Item(
                    line: item.line + offset,
                    quantityLine: item.quantityLine.map { $0 + offset },
                    discountLines: item.discountLines.map { $0 + offset },
                    taxRate: item.taxRate
                )
            }
        )
    }

    func appending(_ other: ReceiptLabels) -> ReceiptLabels {
        ReceiptLabels(
            storeLine: storeLine ?? other.storeLine,
            dateLine: dateLine ?? other.dateLine,
            totalLine: other.totalLine ?? totalLine,
            items: items + other.items
        )
    }
}

extension ReceiptLabels {
    var labeledLines: Set<Int> {
        var lines = Set([storeLine, dateLine, totalLine].compactMap(\.self))

        for item in items {
            lines.insert(item.line)

            if let quantityLine = item.quantityLine {
                lines.insert(quantityLine)
            }

            lines.formUnion(item.discountLines)
        }

        return lines
    }
}

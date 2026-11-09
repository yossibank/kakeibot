import Core

public struct BillPage: Equatable {
    public let month: YearMonth
    public let bills: [CardBill]
}

public extension BillPage {
    static let limit = 2

    var total: Int {
        bills.reduce(0) { $0 + $1.amount }
    }

    var isOpen: Bool {
        bills.contains(where: \.isOpen)
    }

    static func pages(of bills: [CardBill]) -> [BillPage] {
        guard let first = bills.map(\.month).min() else {
            return []
        }

        return (0..<limit).compactMap { offset in
            let month = first.adding(months: offset)
            let members = bills.filter { $0.month == month }

            return members.isEmpty ? nil : BillPage(month: month, bills: members)
        }
    }

    static func page(
        _ index: Int,
        in pages: [BillPage]
    ) -> BillPage? {
        pages.indices.contains(index) ? pages[index] : pages.last
    }
}

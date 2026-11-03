public struct ReviewSummary: Hashable, Sendable {
    public let expense: Breakdown
    public let income: Breakdown

    public init(
        entries: [Entry],
        in range: ClosedRange<LocalDate>
    ) {
        let inRange = entries.filter { range.contains($0.date) }
        let expenses = inRange.filter { $0.type == .expense }
        let incomes = inRange.filter { $0.type == .income }

        self.expense = Breakdown(expenses)
        self.income = Breakdown(incomes)
    }
}

public extension ReviewSummary {
    struct Breakdown: Hashable, Sendable {
        public let total: Int
        public let byCategory: [EntryCategory.ID: Int]
        public let byWallet: [Wallet.ID: Int]
    }

    var balance: Int {
        income.total - expense.total
    }

    func breakdown(of type: Entry.Kind) -> Breakdown? {
        switch type {
        case .expense: expense
        case .income: income
        case .transfer: nil
        }
    }
}

extension ReviewSummary.Breakdown {
    init(_ entries: [Entry]) {
        let total = entries.reduce(0) { $0 + $1.amount }

        var byCategory: [EntryCategory.ID: Int] = [:]
        var byWallet: [Wallet.ID: Int] = [:]

        for entry in entries {
            if let categoryId = entry.categoryId {
                byCategory[categoryId, default: 0] += entry.amount
            }

            byWallet[entry.walletId, default: 0] += entry.amount
        }

        self.init(total: total, byCategory: byCategory, byWallet: byWallet)
    }
}

import Core
import Store

public extension AssetsModel {
    struct Plan: Equatable, Identifiable, Sendable {
        public let id: Entry.ID
        public let date: LocalDate
        public let title: String
        public let wallet: String?
        public let change: Int
    }

    struct OutlookItem: Equatable, Identifiable, Sendable {
        public let source: Source
        public let date: LocalDate
        public let title: String
        public let wallet: String?
        public let change: Int
        public let balance: Int
    }

    struct Outlook: Equatable, Sendable {
        public let end: LocalDate
        public let start: Int
        public let items: [OutlookItem]
        public let later: [Plan]
    }

    struct MonthTotal: Equatable, Sendable {
        public let month: YearMonth
        public let total: Int
        public let netWorth: Int
    }
}

public extension AssetsModel.OutlookItem {
    enum Source: Hashable, Sendable {
        case plan(Entry.ID)
        case recurring(Recurring.ID, LocalDate)
    }
}

public extension AssetsModel.OutlookItem {
    var id: Source {
        source
    }

    var isRecurring: Bool {
        switch source {
        case .plan: false
        case .recurring: true
        }
    }
}

public extension AssetsModel.Outlook {
    var isShown: Bool {
        !items.isEmpty || !later.isEmpty
    }

    var total: Int {
        items.last?.balance ?? start
    }

    var incomes: [AssetsModel.OutlookItem] {
        items.filter { $0.change > 0 }
    }

    var recurringExpenses: [AssetsModel.OutlookItem] {
        items.filter { $0.change < 0 && $0.isRecurring }
    }

    var planExpenses: [AssetsModel.OutlookItem] {
        items.filter { $0.change < 0 && !$0.isRecurring }
    }

    var laterChange: Int {
        later.reduce(0) { $0 + $1.change }
    }

    var lowest: AssetsModel.OutlookItem? {
        guard let lowest = items.min(by: { $0.balance < $1.balance }) else {
            return nil
        }

        let isDip = lowest.balance < start && lowest.balance < total
        let isShort = lowest.balance < 0

        guard isDip || isShort else {
            return nil
        }

        return lowest
    }
}

extension AssetsModel.MonthTotal: Identifiable {
    public var id: YearMonth {
        month
    }
}

import Core

public extension AssetsModel {
    struct WalletRow: Equatable {
        public let wallet: Wallet
        public let icon: Icon?
        public let balance: Int
        public let nextBill: CardBill?
        public let unpaid: Unpaid?
        public let repayment: Repayment?
        public let repaidRatio: Double?
    }

    struct Unpaid: Equatable {
        public let billed: [EntryRowItem]
        public let later: [EntryRowItem]
    }

    enum Repayment: Equatable {
        case unset
        case finished
        case open
        case until(LoanPayoff)
    }

    struct WalletSection: Equatable {
        public let role: Wallet.Kind.Role
        public let rows: [WalletRow]
    }

    struct MonthTotal: Equatable {
        public let month: YearMonth
        public let total: Int
        public let netWorth: Int
    }

    struct UpcomingBill: Equatable {
        public let bill: CardBill
        public let title: String
        public let icon: Icon?
        public let source: String?
        public let movedIn: [EntryRowItem]
        public let movedOut: [EntryRowItem]
    }
}

public extension AssetsModel.WalletRow {
    var repaidPercent: Int? {
        guard
            wallet.kind == .loan,
            let loanAmount = wallet.loanAmount,
            loanAmount > 0
        else {
            return nil
        }

        let repaid = loanAmount - max(-balance, 0)

        return Percent.floor(repaid, of: loanAmount)
    }
}

public extension AssetsModel.Unpaid {
    var count: Int {
        billed.count + later.count
    }
}

extension AssetsModel.WalletRow: Identifiable {
    public var id: Wallet.ID {
        wallet.id
    }
}

extension AssetsModel.WalletSection: Identifiable {
    public var id: Wallet.Kind.Role {
        role
    }
}

extension AssetsModel.MonthTotal: Identifiable {
    public var id: YearMonth {
        month
    }
}

extension AssetsModel.UpcomingBill: Identifiable {
    public var id: Recurring.ID {
        bill.recurring.id
    }
}

import Core

public extension AssetsModel {
    struct WalletRow: Equatable, Sendable {
        public let wallet: Wallet
        public let icon: Icon?
        public let balance: Int
        public let bills: [CardBill]
        public let unpaid: Unpaid?
        public let repayment: Repayment?
        public let repaidRatio: Double?
    }

    struct Unpaid: Equatable, Sendable {
        public let total: Int
        public let bills: [UnpaidBill]
        public let later: [EntryRowItem]
    }

    struct UnpaidBill: Equatable, Sendable {
        public let bill: CardBill
        public let total: Int
        public let rows: [EntryRowItem]
    }

    enum Repayment: Equatable, Sendable {
        case unset
        case finished
        case open
        case until(LoanPayoff)
    }

    struct WalletSection: Equatable, Sendable {
        public let role: Wallet.Kind.Role
        public let rows: [WalletRow]
    }
}

public extension AssetsModel.WalletRow {
    var nextBill: CardBill? {
        bills.first
    }

    var needsAdjustment: Bool {
        wallet.kind.role == .onHand && balance < 0
    }

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
        bills.reduce(later.count) { $0 + $1.rows.count }
    }
}

public extension AssetsModel.WalletSection {
    var isOwed: Bool {
        switch role {
        case .card, .loan: true
        case .onHand, .investment: false
        }
    }

    var total: Int {
        rows.reduce(0) { $0 + $1.balance }
    }
}

extension AssetsModel.WalletSection {
    static func sections(of rows: [AssetsModel.WalletRow]) -> [Self] {
        Wallet.Kind.Role.allCases.compactMap { role in
            let members = rows.filter { $0.wallet.kind.role == role }
            return members.isEmpty ? nil : Self(role: role, rows: members)
        }
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

public extension [AssetsModel.WalletSection] {
    var owned: Self {
        filter { !$0.isOwed }
    }

    var owed: Self {
        filter(\.isOwed)
    }

    var total: Int {
        reduce(0) { $0 + $1.total }
    }

    var rowCount: Int {
        reduce(0) { $0 + $1.rows.count }
    }

    var ownedShare: Double {
        let owned = Swift.max(owned.total, 0)
        let owed = Swift.max(-owed.total, 0)
        let total = owned + owed
        return total == 0 ? 1 : Double(owned) / Double(total)
    }
}

public extension [AssetsModel.WalletRow] {
    var unpaidCount: Int {
        compactMap(\.unpaid).reduce(0) { $0 + $1.count }
    }

    var unpaidTotal: Int {
        compactMap(\.unpaid).reduce(0) { $0 + $1.total }
    }
}

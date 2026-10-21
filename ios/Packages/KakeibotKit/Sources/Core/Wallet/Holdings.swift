public struct Holdings: Hashable, Sendable {
    public let onHand: Int
    public let cards: Int
    public let investments: Int
    public let loans: Int

    public init(
        onHand: Int,
        cards: Int,
        investments: Int,
        loans: Int
    ) {
        self.onHand = onHand
        self.cards = cards
        self.investments = investments
        self.loans = loans
    }
}

public extension Holdings {
    var available: Int {
        onHand + cards
    }

    var netWorth: Int {
        available + investments + loans
    }

    var unpaid: Int {
        max(-cards, 0)
    }

    var refund: Int {
        max(cards, 0)
    }

    init(
        wallets: [Wallet],
        entries: [Entry],
        valuations: [Valuation] = [],
        through date: LocalDate? = nil
    ) {
        func total(_ role: Wallet.Kind.Role) -> Int {
            let wallets = wallets.filter { $0.kind.role == role }
            return Wallet.totalBalance(
                of: wallets,
                with: entries,
                valuations: valuations,
                through: date
            )
        }

        self.init(
            onHand: total(.onHand),
            cards: total(.card),
            investments: total(.investment),
            loans: total(.loan)
        )
    }
}

public extension Wallet.Kind {
    enum Role: CaseIterable, Sendable {
        case onHand
        case card
        case investment
        case loan
    }

    var role: Role {
        switch self {
        case .cash, .bank, .emoney, .point, .other: .onHand
        case .card: .card
        case .investment: .investment
        case .loan: .loan
        }
    }
}

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

    public init(
        wallets: [Wallet],
        entriesByWallet: [Wallet.ID: [Entry]],
        valuations: [Valuation] = [],
        adjustments: [Adjustment] = [],
        through date: LocalDate? = nil
    ) {
        func total(_ role: Wallet.Kind.Role) -> Int {
            wallets
                .filter { $0.kind.role == role }
                .reduce(0) { total, wallet in
                    let balance = wallet.balance(
                        with: entriesByWallet[wallet.id] ?? [],
                        valuations: valuations,
                        adjustments: adjustments,
                        through: date
                    )

                    return total + balance
                }
        }

        let onHand = total(.onHand)
        let cards = total(.card)
        let investments = total(.investment)
        let loans = total(.loan)

        self.init(onHand: onHand, cards: cards, investments: investments, loans: loans)
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

    var isDebt: Bool {
        self == .card || self == .loan
    }
}

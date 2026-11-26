public extension Wallet.Kind {
    enum Role: CaseIterable, Sendable {
        case onHand
        case card
        case investment
        case loan
    }
}

public extension Wallet.Kind {
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

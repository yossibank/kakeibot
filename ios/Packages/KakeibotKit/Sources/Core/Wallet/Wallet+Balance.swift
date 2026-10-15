public extension Wallet {
    static func totalBalance(
        of wallets: [Wallet],
        with entries: [Entry],
        through date: LocalDate? = nil
    ) -> Int {
        wallets.reduce(0) { total, wallet in
            total + wallet.balance(with: entries, through: date)
        }
    }

    func balance(
        with entries: [Entry],
        through date: LocalDate? = nil
    ) -> Int {
        entries.reduce(initialBalance) { balance, entry in
            if let date, date < entry.date {
                return balance
            }

            return balance + change(by: entry)
        }
    }
}

private extension Wallet {
    func change(by entry: Entry) -> Int {
        switch entry.type {
        case .expense:
            entry.walletId == id ? -entry.amount : 0
        case .income:
            entry.walletId == id ? entry.amount : 0
        case .transfer:
            transferChange(by: entry)
        }
    }

    func transferChange(by entry: Entry) -> Int {
        let outgoing = entry.walletId == id ? -entry.amount : 0
        let incoming = entry.toWalletId == id ? entry.amount : 0
        return outgoing + incoming
    }
}

public extension Wallet {
    static func totalBalance(
        of wallets: [Wallet],
        with entries: [Entry],
        valuations: [Valuation] = [],
        adjustments: [Adjustment] = [],
        through date: LocalDate? = nil
    ) -> Int {
        let related = entriesByWallet(entries)

        return wallets.reduce(0) { total, wallet in
            let balance = wallet.balance(
                with: related[wallet.id] ?? [],
                valuations: valuations,
                adjustments: adjustments,
                through: date
            )

            return total + balance
        }
    }

    static func entriesByWallet(_ entries: [Entry]) -> [Wallet.ID: [Entry]] {
        var related: [Wallet.ID: [Entry]] = [:]

        for entry in entries {
            related[entry.walletId, default: []].append(entry)

            if let toWalletId = entry.toWalletId,
               toWalletId != entry.walletId {
                related[toWalletId, default: []].append(entry)
            }
        }

        return related
    }

    func balance(
        with entries: [Entry],
        valuations: [Valuation] = [],
        adjustments: [Adjustment] = [],
        through date: LocalDate? = nil
    ) -> Int {
        let valuation = kind == .investment ? latestValuation(in: valuations, through: date) : nil
        let start = valuation?.amount ?? initialBalance

        let recorded = entries.reduce(start) { balance, entry in
            if let date,
               date < entry.date {
                return balance
            }

            if let valuation,
               valuation.includes(entry) {
                return balance
            }

            return balance + change(by: entry)
        }

        return adjustments.reduce(recorded) { balance, adjustment in
            guard adjustment.walletId == id else {
                return balance
            }

            if let date,
               date < adjustment.date {
                return balance
            }

            if let valuation,
               valuation.includes(adjustment) {
                return balance
            }

            return balance + adjustment.amount
        }
    }
}

private extension Wallet {
    func latestValuation(
        in valuations: [Valuation],
        through date: LocalDate?
    ) -> Valuation? {
        valuations
            .filter { valuation in
                valuation.walletId == id
                    && date.map { valuation.date <= $0 } ?? true
            }
            .max { $0.date < $1.date }
    }

    func change(by entry: Entry) -> Int {
        switch entry.type {
        case .expense: entry.walletId == id ? -entry.amount : 0
        case .income: entry.walletId == id ? entry.amount : 0
        case .transfer: transferChange(by: entry)
        }
    }

    func transferChange(by entry: Entry) -> Int {
        let outgoing = entry.walletId == id ? -entry.amount : 0
        let incoming = entry.toWalletId == id ? entry.amount : 0
        return outgoing + incoming
    }
}

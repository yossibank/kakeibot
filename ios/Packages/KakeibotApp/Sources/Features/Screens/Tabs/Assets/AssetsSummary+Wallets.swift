import Core
import Store

extension AssetsSummary.Input {
    func rows(
        of wallets: [Wallet],
        bills: [AssetsModel.UpcomingBill]
    ) -> [AssetsModel.WalletRow] {
        let billsByCard = Dictionary(grouping: bills.map(\.bill)) { $0.recurring.toWalletId }

        return wallets.map { wallet in
            let cardBills = billsByCard[wallet.id] ?? []
            let balance = balance(of: wallet)
            let ratio = Self.repaidRatio(of: wallet, balance: balance)

            return AssetsModel.WalletRow(
                wallet: wallet,
                icon: list?.icons[wallet.iconId],
                balance: balance,
                bills: cardBills,
                unpaid: unpaid(of: cardBills),
                repayment: repayment(of: wallet, balance: balance),
                repaidRatio: ratio
            )
        }
    }

    func entryRows(of entries: [Entry]) -> [EntryRowItem] {
        guard let list else {
            return []
        }

        return entries
            .sorted { $0.date < $1.date }
            .map { EntryRowItem.dated($0, in: list) }
    }
}

private extension AssetsSummary.Input {
    static func repaidRatio(
        of wallet: Wallet,
        balance: Int
    ) -> Double? {
        guard
            wallet.kind == .loan,
            let loanAmount = wallet.loanAmount,
            loanAmount > 0
        else {
            return nil
        }

        let repaid = Wallet.repaid(borrowed: loanAmount, balance: balance)

        return Double(repaid) / Double(loanAmount)
    }

    func balance(of wallet: Wallet) -> Int {
        wallet.balance(
            with: entries(of: wallet.id),
            valuations: list?.valuations ?? [],
            adjustments: list?.adjustments ?? [],
            through: today
        )
    }

    func repayment(
        of wallet: Wallet,
        balance: Int
    ) -> AssetsModel.Repayment? {
        guard wallet.kind == .loan else {
            return nil
        }

        if balance >= 0 {
            return .finished
        }

        let repayments = recurrings.filter { recurring in
            recurring.type == .transfer && recurring.toWalletId == wallet.id
        }

        if repayments.isEmpty {
            return .unset
        }

        let payoff = LoanPayoff(
            balance: balance,
            repayments: repayments,
            after: today
        )

        return payoff.map(AssetsModel.Repayment.until) ?? .open
    }
}

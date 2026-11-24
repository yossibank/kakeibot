import Core
import DesignSystem
import Foundation
import Store

public extension EntryModel.Output {
    var wallets: [Wallet] {
        let wallets = input.options?.wallets ?? []

        guard isEditing else {
            return wallets
        }

        let kept = [state.payment.walletId, state.payment.toWalletId]
            .compactMap(\.self)
            .filter { id in !wallets.contains { $0.id == id } }
            .compactMap { input.history?.wallets[$0] }

        return (wallets + kept).sorted { $0.sortOrder < $1.sortOrder }
    }

    var walletSections: [EntryModel.WalletSection] {
        Wallet.Kind.allCases.compactMap { kind in
            let wallets = wallets.filter { $0.kind == kind }

            return wallets.isEmpty
                ? nil
                : EntryModel.WalletSection(kind: kind, wallets: wallets)
        }
    }

    var walletName: String {
        wallet(state.payment.walletId)?.name ?? walletTitle
    }

    var walletTitle: String {
        state.type.walletTitle
    }

    var isUsualWallet: Bool {
        state.type == .transfer || state.payment.walletId == usualWalletId
    }

    var billText: String? {
        guard
            state.payment.billMonth != nil,
            let date = selectedBillDate
        else {
            return nil
        }

        return Recurring.billText(paidOn: date)
    }

    var billRecurring: Recurring? {
        guard
            state.type != .transfer,
            let walletId = state.payment.walletId
        else {
            return nil
        }

        return input.cardBills.cardBill(paidBy: walletId)
    }

    var billChoices: [EntryModel.BillChoice] {
        guard let bill = billRecurring else {
            return []
        }

        let dates = bill.billDates(for: state.payment.date, count: Recurring.billChoiceCount)

        return zip(dates, Recurring.billShiftTitles).map { date, title in
            EntryModel.BillChoice(
                date: date,
                title: title,
                period: bill.billingPeriod(paidOn: date)
            )
        }
    }

    var selectedBillDate: LocalDate? {
        let choices = billChoices
        let recurring = billRecurring
        let billMonth = state.payment.billMonth

        let chosen = choices.first {
            recurring?.occurrenceMonth(of: $0.date) == billMonth
        }

        return chosen?.date ?? choices.first?.date
    }

    func icon(for wallet: Wallet) -> Icon? {
        input.options?.icons[wallet.iconId]
    }

    func isShared(_ wallet: Wallet) -> Bool {
        input.options?.sharedWalletIds.contains(wallet.id) ?? false
    }

    func wallet(_ id: Wallet.ID?) -> Wallet? {
        wallets.first { $0.id == id }
    }

    func balance(of wallet: Wallet) -> Int? {
        input.balances[wallet.id]
    }

    func balanceText(of wallet: Wallet) -> String? {
        guard let balance = balance(of: wallet) else {
            return nil
        }

        switch wallet.kind.role {
        case .loan: return "残り \(Yen.text(max(-balance, 0)))"
        case .investment: return "評価額 \(Yen.text(balance))"
        case .onHand, .card: return "残高 \(Yen.text(balance))"
        }
    }
}

extension EntryModel.Output {
    var usualWalletId: Wallet.ID? {
        let recent = recentWalletIds[state.type]
        return wallets.contains { $0.id == recent } ? recent : wallets.first?.id
    }
}

private extension EntryModel.Output {
    var recentWalletIds: [Entry.Kind: Wallet.ID] {
        recentWalletsCache.value {
            latestWalletIds
        }
    }

    var latestWalletIds: [Entry.Kind: Wallet.ID] {
        let entries = (input.history?.entries ?? [])
            .filter { $0.type != .transfer && $0.transferId == nil }
            .sorted { $0.createdAt > $1.createdAt }

        var ids: [Entry.Kind: Wallet.ID] = [:]

        for entry in entries where ids[entry.type] == nil {
            ids[entry.type] = entry.walletId
        }

        return ids
    }
}

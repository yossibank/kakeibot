import Core
import DesignSystem
import Foundation
import Store

public extension EntryModel.Output {
    var recentTransfers: [Entry] {
        let fees = feesByTransfer

        var seen: Set<String> = []

        let unique = manualTransfers.filter { entry in
            let route = "\(entry.walletId)>\(String(describing: entry.toWalletId))"
            let key = "\(route)>\(entry.amount)>\(fees[entry.id] ?? 0)"
            return seen.insert(key).inserted
        }

        return Array(unique.prefix(EntryModel.recentTransferLimit))
    }

    var frequentRoutes: [EntryModel.TransferRoute] {
        let routes = manualTransfers.compactMap(Self.route(of:))
        let counts = Dictionary(routes.map { ($0, 1) }, uniquingKeysWith: +)

        var seen: Set<EntryModel.TransferRoute> = []

        let ordered = routes.filter { seen.insert($0).inserted }

        let sorted = ordered.enumerated().sorted { lhs, rhs in
            let left = counts[lhs.element, default: 0]
            let right = counts[rhs.element, default: 0]
            return left == right ? lhs.offset < rhs.offset : left > right
        }

        return sorted.prefix(EntryModel.frequentRouteLimit).map(\.element)
    }

    var isOverSourceBalance: Bool {
        guard
            state.type == .transfer,
            amount > 0,
            let balance = wallet(state.payment.walletId).flatMap(balance(of:)) else {
            return false
        }

        return amount + fee > balance
    }

    var loanRemaining: Int? {
        guard
            state.type == .transfer,
            let wallet = wallet(state.payment.toWalletId),
            wallet.kind == .loan,
            let balance = balance(of: wallet),
            balance < 0
        else {
            return nil
        }

        return -balance
    }

    func currentLine(of wallet: Wallet) -> EntryModel.BalanceLine? {
        guard let balance = balance(of: wallet) else {
            return nil
        }

        switch wallet.kind.role {
        case .loan: return EntryModel.BalanceLine(title: "今の残り", amount: max(-balance, 0))
        case .investment: return EntryModel.BalanceLine(title: "今の評価額", amount: balance)
        case .onHand, .card: return EntryModel.BalanceLine(title: "残高", amount: balance)
        }
    }

    func afterLine(
        of wallet: Wallet,
        isSource: Bool
    ) -> EntryModel.BalanceLine? {
        guard
            state.type == .transfer,
            amount > 0,
            let balance = balance(of: wallet)
        else {
            return nil
        }

        let after = isSource ? balance - amount - fee : balance + amount
        let shown = wallet.kind.role == .loan ? max(-after, 0) : after

        return EntryModel.BalanceLine(
            title: afterTitle(of: wallet, isSource: isSource),
            amount: shown
        )
    }

    func idleAfterLine(
        of wallet: Wallet,
        isSource: Bool
    ) -> EntryModel.BalanceLine? {
        currentLine(of: wallet).map { current in
            EntryModel.BalanceLine(
                title: afterTitle(of: wallet, isSource: isSource),
                amount: current.amount
            )
        }
    }

    func afterTitle(
        of wallet: Wallet,
        isSource: Bool
    ) -> String {
        switch (wallet.kind.role, isSource) {
        case (.loan, false): "返済後"
        case (.investment, false): "積立後"
        default: "振替後"
        }
    }

    func fee(of transfer: Entry) -> Int {
        let entries = input.history?.entries ?? []
        return entries.first { $0.transferId == transfer.id }?.amount ?? 0
    }
}

private extension EntryModel.Output {
    var manualTransfers: [Entry] {
        let shown = Set(wallets.map(\.id))
        let editingId = input.editingId

        return (input.history?.entries ?? [])
            .filter { entry in
                entry.type == .transfer
                    && entry.recurringId == nil
                    && entry.id != editingId
                    && shown.contains(entry.walletId)
                    && entry.toWalletId.map(shown.contains) == true
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var feesByTransfer: [Entry.ID: Int] {
        let fees = (input.history?.entries ?? []).compactMap { entry in
            entry.transferId.map { ($0, entry.amount) }
        }

        return Dictionary(fees) { first, _ in first }
    }

    static func route(of entry: Entry) -> EntryModel.TransferRoute? {
        entry.toWalletId.map { EntryModel.TransferRoute(walletId: entry.walletId, toWalletId: $0) }
    }
}

import Core
import DesignSystem
import Foundation
import Store

public extension EntryModel {
    struct TransferRoute: Hashable {
        public let walletId: Wallet.ID
        public let toWalletId: Wallet.ID
    }

    struct BalanceLine: Equatable {
        public let title: String
        public let amount: Int
    }

    static let recentTransferLimit = 3
    static let frequentRouteLimit = 6
    static let destinationTitle = "振替先"

    var transferProgress: Double? {
        guard
            type == .transfer,
            let balance = wallet(walletId).flatMap(balance(of:)),
            balance > 0
        else {
            return nil
        }

        return min(max(Double(amount + fee) / Double(balance), 0), 1)
    }

    var recentTransfers: [Entry] {
        var seen: Set<String> = []

        let unique = manualTransfers.filter { entry in
            let route = "\(entry.walletId)>\(String(describing: entry.toWalletId))"
            let key = "\(route)>\(entry.amount)>\(fee(of: entry))"
            return seen.insert(key).inserted
        }

        return Array(unique.prefix(Self.recentTransferLimit))
    }

    var frequentRoutes: [TransferRoute] {
        let routes = manualTransfers.compactMap(Self.route(of:))
        let counts = Dictionary(routes.map { ($0, 1) }, uniquingKeysWith: +)

        var seen: Set<TransferRoute> = []

        let ordered = routes.filter { seen.insert($0).inserted }

        let sorted = ordered.enumerated().sorted { lhs, rhs in
            let left = counts[lhs.element, default: 0]
            let right = counts[rhs.element, default: 0]
            return left == right ? lhs.offset < rhs.offset : left > right
        }

        return sorted.prefix(Self.frequentRouteLimit).map(\.element)
    }

    var routeText: String? {
        guard
            let source = wallet(walletId),
            let destination = wallet(toWalletId)
        else {
            return nil
        }

        return "\(source.name) → \(destination.name)"
    }

    var sourceBalanceText: String? {
        guard
            type == .transfer,
            let source = wallet(walletId),
            let line = afterLine(of: source, isSource: true) ?? currentLine(of: source)
        else {
            return nil
        }

        return "\(source.name) \(line.title) \(AmountText.text(line.amount))"
    }

    var isOverSourceBalance: Bool {
        guard
            type == .transfer,
            amount > 0
        else {
            return false
        }

        guard let balance = wallet(walletId).flatMap(balance(of:)) else {
            return false
        }

        return amount + fee > balance
    }

    var loanRemaining: Int? {
        guard
            type == .transfer,
            let wallet = wallet(toWalletId),
            wallet.kind == .loan,
            let balance = balance(of: wallet),
            balance < 0
        else {
            return nil
        }

        return -balance
    }

    func currentLine(of wallet: Wallet) -> BalanceLine? {
        guard let balance = balance(of: wallet) else {
            return nil
        }

        switch wallet.kind.role {
        case .loan: return BalanceLine(title: "今の残り", amount: max(-balance, 0))
        case .investment: return BalanceLine(title: "今の評価額", amount: balance)
        case .onHand, .card: return BalanceLine(title: "残高", amount: balance)
        }
    }

    func afterLine(
        of wallet: Wallet,
        isSource: Bool
    ) -> BalanceLine? {
        guard
            type == .transfer,
            amount > 0,
            let balance = balance(of: wallet)
        else {
            return nil
        }

        let after = isSource ? balance - amount - fee : balance + amount
        let shown = wallet.kind.role == .loan ? max(-after, 0) : after

        return BalanceLine(title: afterTitle(of: wallet, isSource: isSource), amount: shown)
    }

    func idleAfterLine(
        of wallet: Wallet,
        isSource: Bool
    ) -> BalanceLine? {
        currentLine(of: wallet).map { current in
            BalanceLine(title: afterTitle(of: wallet, isSource: isSource), amount: current.amount)
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
        let entries = history?.days.flatMap(\.entries) ?? []
        return entries.first { $0.transferId == transfer.id }?.amount ?? 0
    }

    func payOffLoan() {
        guard let loanRemaining else {
            return
        }

        calculator = AmountCalculator(amount: loanRemaining)
    }

    func applyRoute(_ route: TransferRoute) {
        walletId = route.walletId
        toWalletId = route.toWalletId
    }

    func applyTransfer(_ entry: Entry) {
        walletId = entry.walletId
        toWalletId = entry.toWalletId
        calculator = AmountCalculator(amount: entry.amount)
        feeCalculator = AmountCalculator(amount: fee(of: entry))
    }

    func swapWallets() {
        let source = walletId
        walletId = toWalletId
        toWalletId = source
    }
}

extension EntryModel {
    func chooseDestination() {
        guard toWalletId == nil || toWalletId == walletId else {
            return
        }

        toWalletId = wallets.first { $0.id != walletId }?.id
    }
}

private extension EntryModel {
    var manualTransfers: [Entry] {
        (history?.days ?? [])
            .flatMap(\.entries)
            .filter { entry in
                entry.type == .transfer
                    && entry.recurringId == nil
                    && entry.id != editingId
                    && wallet(entry.walletId) != nil
                    && wallet(entry.toWalletId) != nil
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    static func route(of entry: Entry) -> TransferRoute? {
        entry.toWalletId.map { TransferRoute(walletId: entry.walletId, toWalletId: $0) }
    }
}

import Core
import DesignSystem
import Foundation
import Store

public extension ReviewModel {
    struct Move: Identifiable {
        public let wallet: Wallet
        public let icon: Icon?
        public let amount: Int
        public let balance: Int
        public let payoff: LoanPayoff?

        public var id: Wallet.ID {
            wallet.id
        }
    }

    var moves: [Move] {
        guard let list else {
            return []
        }

        return list.wallets.values
            .filter { Self.moveRoles.contains($0.kind.role) }
            .sorted { lhs, rhs in
                let lhsOrder = Self.moveRoles.firstIndex(of: lhs.kind.role) ?? 0
                let rhsOrder = Self.moveRoles.firstIndex(of: rhs.kind.role) ?? 0

                if lhsOrder != rhsOrder {
                    return lhsOrder < rhsOrder
                }

                return lhs.sortOrder < rhs.sortOrder
            }
            .compactMap { wallet in
                let amount = moveEntries(to: wallet, in: list).reduce(0) { $0 + $1.amount }

                guard amount > 0 else {
                    return nil
                }

                let balance = wallet.balance(
                    with: entries,
                    valuations: list.valuations,
                    through: today
                )

                return Move(
                    wallet: wallet,
                    icon: list.icons[wallet.iconId],
                    amount: amount,
                    balance: balance,
                    payoff: payoff(of: wallet, balance: balance)
                )
            }
    }

    static func total(of moves: [Move]) -> Int {
        moves.reduce(0) { $0 + $1.amount }
    }

    func repaymentRatio(in moves: [Move]) -> Double {
        let total = Self.total(of: moves)

        let repaid = moves
            .filter { $0.wallet.kind.role == .loan }
            .reduce(0) { $0 + $1.amount }

        return total == 0 ? 0 : Double(repaid) / Double(total)
    }

    func share(of move: Move) -> Share {
        Share(
            id: AnyHashable(MoveKey(walletId: move.wallet.id)),
            name: move.wallet.name,
            icon: move.icon,
            amount: move.amount,
            ratio: 0,
            usage: nil
        )
    }
}

extension ReviewModel {
    struct MoveKey: Hashable {
        let walletId: Wallet.ID
    }

    func moveRows(to walletId: Wallet.ID) -> [EntryRowItem] {
        guard
            let list,
            let wallet = list.wallets[walletId]
        else {
            return []
        }

        return moveEntries(to: wallet, in: list)
            .sorted { $0.date > $1.date }
            .map { entry in
                let label = "\(entry.date.month)/\(entry.date.day)"

                return EntryRowItem(entry, in: list, dayLabel: label)
            }
    }
}

private extension ReviewModel {
    static let moveRoles: [Wallet.Kind.Role] = [.loan, .investment]

    func moveEntries(
        to wallet: Wallet,
        in list: EntryList
    ) -> [Entry] {
        entries.filter { entry in
            let from = list.wallets[entry.walletId]?.kind.role

            return entry.type == .transfer
                && entry.toWalletId == wallet.id
                && from != wallet.kind.role
                && period.range.contains(entry.date)
        }
    }

    func payoff(
        of wallet: Wallet,
        balance: Int
    ) -> LoanPayoff? {
        guard
            wallet.kind == .loan,
            balance < 0
        else {
            return nil
        }

        let repayments = recurrings.filter { recurring in
            recurring.type == .transfer && recurring.toWalletId == wallet.id
        }

        return LoanPayoff(
            balance: balance,
            repayments: repayments,
            after: today
        )
    }
}

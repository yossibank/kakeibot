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
    }

    struct MoveKey: Hashable, Sendable {
        let walletId: Wallet.ID
    }
}

public extension ReviewModel {
    static func total(of moves: [Move]) -> Int {
        moves.reduce(0) { $0 + $1.amount }
    }
}

private extension ReviewModel {
    static let moveRoles: [Wallet.Kind.Role] = [.loan, .investment]
}

public extension ReviewModel.Move {
    var id: Wallet.ID {
        wallet.id
    }
}

public extension ReviewModel.Output {
    var moves: [ReviewModel.Move] {
        moveLists.value(for: period.range) {
            _ = input.recurrings
            return input.list.value.map { moves(in: $0) } ?? []
        }
    }

    func repaymentRatio(in moves: [ReviewModel.Move]) -> Double {
        let total = ReviewModel.total(of: moves)

        let repaid = moves
            .filter { $0.wallet.kind.role == .loan }
            .reduce(0) { $0 + $1.amount }

        return total == 0 ? 0 : Double(repaid) / Double(total)
    }

    func share(of move: ReviewModel.Move) -> ReviewModel.Share {
        ReviewModel.Share(
            id: .move(ReviewModel.MoveKey(walletId: move.wallet.id)),
            name: move.wallet.name,
            icon: move.icon,
            amount: move.amount,
            ratio: 0,
            usage: nil
        )
    }
}

extension ReviewModel.Output {
    func moveRows(to walletId: Wallet.ID) -> [EntryRowItem] {
        guard
            let list = input.list.value,
            let wallet = list.wallets[walletId]
        else {
            return []
        }

        return moveEntries(to: wallet, in: list)
            .sorted { $0.date > $1.date }
            .map { entry in
                EntryRowItem.dated(entry, in: list)
            }
    }
}

private extension ReviewModel.Output {
    func moves(in list: EntryList) -> [ReviewModel.Move] {
        list.wallets.values
            .filter { ReviewModel.moveRoles.contains($0.kind.role) }
            .sorted { lhs, rhs in
                let lhsOrder = ReviewModel.moveRoles.firstIndex(of: lhs.kind.role) ?? 0
                let rhsOrder = ReviewModel.moveRoles.firstIndex(of: rhs.kind.role) ?? 0

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

                let balance = list.balance(of: wallet, through: state.today)

                return ReviewModel.Move(
                    wallet: wallet,
                    icon: list.icons[wallet.iconId],
                    amount: amount,
                    balance: balance,
                    payoff: payoff(of: wallet, balance: balance)
                )
            }
    }

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

        let repayments = input.recurrings.filter { recurring in
            recurring.type == .transfer && recurring.toWalletId == wallet.id
        }

        return LoanPayoff(
            balance: balance,
            repayments: repayments,
            after: state.today
        )
    }
}

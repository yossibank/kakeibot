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

    func payOffLoan() {
        guard let loanRemaining = output.loanRemaining else {
            return
        }

        state.keypad.setAmount(loanRemaining)
    }

    func applyRoute(_ route: TransferRoute) {
        setWallet(route.walletId)
        state.setDestination(route.toWalletId)
    }

    func applyTransfer(_ entry: Entry) {
        setWallet(entry.walletId)
        state.setDestination(entry.toWalletId)
        state.keypad.setAmount(entry.amount)
        state.keypad.setFee(output.fee(of: entry))
    }

    func swapWallets() {
        let source = state.payment.walletId
        setWallet(state.payment.toWalletId)
        state.setDestination(source)
    }
}

extension EntryModel {
    func chooseDestination() {
        let walletId = state.payment.walletId
        let toWalletId = state.payment.toWalletId

        guard toWalletId == nil || toWalletId == walletId else {
            return
        }

        state.setDestination(output.wallets.first { $0.id != walletId }?.id)
    }
}

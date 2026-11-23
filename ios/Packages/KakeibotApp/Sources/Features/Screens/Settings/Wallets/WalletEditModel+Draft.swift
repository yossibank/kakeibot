import Core

public extension WalletEditModel {
    var initialBalance: Int {
        isNegative ? -calculator.amount : calculator.amount
    }

    var draft: WalletDraft {
        let loan = loanAmount.amount > 0 ? loanAmount.amount : nil

        return WalletDraft(
            kind: kind,
            name: name,
            mark: icon.mark,
            color: icon.color,
            initialBalance: initialBalance,
            loanAmount: loan,
            recordedKind: recordedKind,
            hasValuations: hasValuations
        )
    }

    var needsHideConfirmation: Bool {
        !isHidden && totalBalance != 0
    }
}

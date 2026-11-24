import Core

public extension WalletEditModel {
    @MainActor
    final class Output {
        let input: Input
        let state: State

        init(
            input: Input,
            state: State
        ) {
            self.input = input
            self.state = state
        }
    }
}

public extension WalletEditModel.Output {
    var initialBalance: Int {
        state.isNegative ? -state.calculator.amount : state.calculator.amount
    }

    var draft: WalletDraft {
        let loan = state.loanAmount.amount > 0 ? state.loanAmount.amount : nil

        return WalletDraft(
            kind: state.kind,
            name: state.name,
            mark: state.icon.mark,
            color: state.icon.color,
            initialBalance: initialBalance,
            loanAmount: loan,
            recordedKind: input.recordedKind,
            hasValuations: input.hasValuations
        )
    }

    var needsHideConfirmation: Bool {
        !input.isHidden && input.totalBalance != 0
    }
}

extension WalletEditModel.Output {
    var isEditing: Bool {
        input.editingId != nil
    }
}

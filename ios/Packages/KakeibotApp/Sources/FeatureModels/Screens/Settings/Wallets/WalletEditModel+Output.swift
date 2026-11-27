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
        state.isNegative ? -state.submodels.calculator.amount : state.submodels.calculator.amount
    }

    var draft: WalletDraft {
        let loan = state.submodels.loanAmount.amount > 0 ? state.submodels.loanAmount.amount : nil

        return WalletDraft(
            kind: state.kind,
            name: state.fields.name,
            mark: state.submodels.icon.mark,
            color: state.submodels.icon.state.fields.color,
            initialBalance: initialBalance,
            loanAmount: loan,
            recordedKind: input.recordedKind,
            hasValuations: input.hasValuations
        )
    }
}

extension WalletEditModel.Output {
    var isEditing: Bool {
        input.editingId != nil
    }
}

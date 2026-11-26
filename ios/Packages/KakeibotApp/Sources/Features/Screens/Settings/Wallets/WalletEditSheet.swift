import Core
import DesignSystem
import FeatureModels
import SwiftUI

public struct WalletEditSheet: View {
    @State var model: WalletEditModel
    @State var layout = Layout()

    @FocusState var focus: Field?

    @Environment(\.dismiss) var dismiss
    @Environment(\.themeStyle.corner) var corner

    let onSave: (Wallet) -> Void
    let onDelete: (Deletion) -> Void
    let onHide: () -> Void

    public init(
        model: WalletEditModel,
        onSave: @escaping (Wallet) -> Void = { _ in },
        onDelete: @escaping (Deletion) -> Void = { _ in },
        onHide: @escaping () -> Void = {}
    ) {
        _model = State(initialValue: model)

        self.onSave = onSave
        self.onDelete = onDelete
        self.onHide = onHide
    }

    public var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .bottom) {
                content

                if model.state.prompt.panel == .amount {
                    amountDrawer(
                        "最初の残高",
                        calculator: model.state.calculator,
                        amount: model.output.initialBalance,
                        onPress: model.state.press,
                        onDismiss: closeAmount,
                        onDone: closeAmount
                    )
                }

                if model.state.prompt.panel == .valuation {
                    amountDrawer(
                        "今の評価額",
                        calculator: model.state.valuation,
                        onPress: model.state.pressValuation,
                        onDismiss: closeValuation
                    ) {
                        saveValuation()
                    } button: {
                        PrimaryButton("評価額を保存") {
                            saveValuation()
                        }
                    }
                }

                if model.state.prompt.panel == .loanAmount {
                    amountDrawer(
                        "最初に借りた額",
                        calculator: model.state.loanAmount,
                        onPress: model.state.pressLoanAmount,
                        onDismiss: closeLoanAmount,
                        onDone: closeLoanAmount
                    )
                }
            }
            .animation(.snappy, value: model.state.prompt.panel)
        }
        .iconEditorDrawer(
            model: model.state.icon,
            focus: $focus,
            textField: .text,
            below: layout.iconBottom
        )
        .errorBanner(Bindable(model.state).errorNotice)
        .deletionNotice(Bindable(model.state).valuationDeletion) { deletion in
            model.perform {
                await $0.restore(deletion)
            }
        }
        .settingsEditConfirmations(edit)
        .confirmsWalletDelete(
            hasEntries: model.input.hasEntries,
            isPresented: Bindable(model.state).prompt.isConfirmingDelete
        ) {
            toggleHidden()
        } onConfirm: {
            edit.delete()
        }
        .confirmsWalletHide(
            balance: model.input.balance,
            isPresented: Bindable(model.state).prompt.isConfirmingHide
        ) {
            edit.toggleHidden()
        }
        .onChange(of: model.state.kind) {
            focus = nil
        }
        .sheet(isPresented: Bindable(model.state).payment.isEditing) {
            closePayment()
        } content: {
            RecurringEditSheet(model: model.paymentModel())
        }
        .confirmation(
            isPresented: Bindable(model.state).payment.isAsking,
            systemImage: "repeat",
            title: model.output.paymentQuestion,
            message: model.output.paymentQuestionNote,
            keepTitle: "あとで",
            confirmTitle: "決める",
            role: .suggestion,
            onKeep: model.finishAddedWallet
        ) {
            model.state.payment.isEditing = true
        }
        .task {
            await model.load()
        }
        .presentationSizing(.tallForm)
    }
}

extension WalletEditSheet: SettingsEditSheet {
    init(
        model: WalletEditModel,
        onDelete: @escaping (Deletion) -> Void,
        onHide: @escaping () -> Void
    ) {
        self.init(
            model: model,
            onSave: { _ in },
            onDelete: onDelete,
            onHide: onHide
        )
    }
}

#Preview {
    if let parts = ScreenParts.preview() {
        WalletEditSheet(model: WalletEditModel(parts: parts))
    }
}

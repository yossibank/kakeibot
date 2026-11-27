import Core
import DesignSystem
import FeatureModels
import SwiftUI

public struct WalletEditSheet: View {
    @State var model: WalletEditModel
    @State var layout = Layout()

    @FocusState var focus: Field?

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
            editorStack
        }
        .iconEditorDrawer(
            model: model.state.icon,
            focus: $focus,
            textField: .text,
            below: layout.iconBottom
        )
        .errorBanner(model.state.errorNotice)
        .deletionNotice(model.state.valuationDeletion) { deletion in
            model.perform {
                await $0.restore(deletion)
            }
        }
        .editSheet(
            model.flow,
            deleting: .deletingWallet(hasEntries: model.input.hasEntries),
            hiding: .hidingWallet(balance: model.input.balance),
            onHide: onHide,
            onDelete: onDelete,
            onSaved: onSave
        )
        .onChange(of: model.state.kind) {
            focus = nil
        }
        .sheet(isPresented: Bindable(model.state).payment.shown[.editing]) {
            closePayment()
        } content: {
            RecurringEditSheet(model: model.paymentModel())
        }
        .confirmation(
            isPresented: Bindable(model.state).payment.shown[.asking],
            systemImage: "repeat",
            title: model.output.paymentQuestion,
            message: model.output.paymentQuestionNote,
            keepTitle: "あとで",
            confirmTitle: "決める",
            role: .suggestion,
            onKeep: model.finishAddedWallet
        ) {
            model.state.payment.shown.show(.editing)
        }
        .task {
            await model.load()
        }
        .presentationSizing(.tallForm)
    }
}

private extension WalletEditSheet {
    var editorStack: some View {
        ZStack(alignment: .bottom) {
            content

            if model.state.panel.isShowing(.amount) {
                amountDrawer(
                    "最初の残高",
                    calculator: model.state.calculator,
                    amount: model.output.initialBalance,
                    onPress: model.state.press,
                    onDismiss: closeAmount,
                    onDone: closeAmount
                )
            }

            if model.state.panel.isShowing(.valuation) {
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

            if model.state.panel.isShowing(.loanAmount) {
                amountDrawer(
                    "最初に借りた額",
                    calculator: model.state.loanAmount,
                    onPress: model.state.pressLoanAmount,
                    onDismiss: closeLoanAmount,
                    onDone: closeLoanAmount
                )
            }
        }
        .animation(.snappy, value: model.state.panel)
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

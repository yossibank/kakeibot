import Core
import DesignSystem
import Store
import SwiftUI

public struct WalletEditSheet: View {
    @State var model: WalletEditModel
    @State var isConfirmingDiscard = false
    @State var isConfirmingHideChanges = false
    @State var isEnteringAmount = false
    @State var isEnteringValuation = false
    @State var isEnteringLoanAmount = false
    @State var isEditingIcon = false
    @State var iconBottom: CGFloat = 0
    @State var openValuationId: Valuation.ID?
    @State var isConfirmingHide = false
    @State var isConfirmingDelete = false
    @State var isEditingPayment = false
    @State var isAskingPayment = false
    @State var addedWallet: Wallet?
    @State var valuationDeletion: Deletion?

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

                if isEnteringAmount {
                    amountDrawer(
                        "最初の残高",
                        calculator: model.state.calculator,
                        amount: model.output.initialBalance,
                        onPress: model.state.press,
                        onDismiss: closeAmount,
                        onDone: closeAmount
                    )
                }

                if isEnteringValuation {
                    amountDrawer(
                        "今の評価額",
                        calculator: model.state.valuation,
                        onPress: model.state.pressValuation,
                        onDismiss: closeValuation
                    ) {
                        Task {
                            await saveValuation()
                        }
                    } button: {
                        PrimaryButton("評価額を保存") {
                            Task {
                                await saveValuation()
                            }
                        }
                    }
                }

                if isEnteringLoanAmount {
                    amountDrawer(
                        "最初に借りた額",
                        calculator: model.state.loanAmount,
                        onPress: model.state.pressLoanAmount,
                        onDismiss: closeLoanAmount,
                        onDone: closeLoanAmount
                    )
                }
            }
        }
        .iconEditorDrawer(
            isPresented: $isEditingIcon,
            model: model.state.icon,
            focus: $focus,
            textField: .text,
            below: iconBottom
        )
        .errorBanner(Bindable(model.state).errorNotice)
        .deletionNotice($valuationDeletion) { deletion in
            Task {
                await model.restore(deletion)
            }
        }
        .confirmsUnsavedHide(
            isHidden: model.input.isHidden,
            canSave: model.canSave,
            isPresented: $isConfirmingHideChanges
        ) {
            Task {
                await save(hiding: true)
            }
        } onDiscard: {
            Task {
                await setHidden(!model.input.isHidden)
            }
        }
        .confirmsDiscard(when: model.isChanged, isPresented: $isConfirmingDiscard) {
            dismiss()
        }
        .confirmsWalletDelete(
            hasEntries: model.input.hasEntries,
            isPresented: $isConfirmingDelete
        ) {
            toggleHidden()
        } onConfirm: {
            Task {
                await delete()
            }
        }
        .confirmsWalletHide(balance: model.input.balance, isPresented: $isConfirmingHide) {
            requestHide()
        }
        .onChange(of: model.state.kind) {
            focus = nil
        }
        .sheet(isPresented: $isEditingPayment) {
            closePayment()
        } content: {
            RecurringEditSheet(model: model.paymentModel(for: addedWallet?.id))
        }
        .confirmation(
            isPresented: $isAskingPayment,
            systemImage: "repeat",
            title: model.output.paymentQuestion,
            message: model.output.paymentQuestionNote,
            keepTitle: "あとで",
            confirmTitle: "決める",
            role: .suggestion,
            onKeep: finishAddedWallet
        ) {
            isEditingPayment = true
        }
        .task {
            await model.load()
        }
        .presentationSizing(.tallForm)
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        let _ = try? database.insertDefaultsIfEmpty(at: Date())

        WalletEditSheet(model: WalletEditModel(database: database, clock: .system))
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

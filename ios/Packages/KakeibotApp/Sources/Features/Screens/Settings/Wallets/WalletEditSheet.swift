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
                    Palette.scrim
                        .opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture {
                            closeAmount()
                        }
                        .transition(.opacity)
                        .zIndex(1)

                    SettingsDrawer("最初の残高", showsDone: false) {
                        closeAmount()
                    } content: {
                        VStack(spacing: 12) {
                            Keypad(calculator: model.calculator) {
                                closeAmount()
                            } onKey: { key in
                                model.press(key)
                            }

                            saveButton
                        }
                    }
                    .transition(.settingsDrawer)
                    .zIndex(1)
                }

                if isEnteringValuation {
                    amountDrawer(
                        "今の評価額",
                        calculator: model.valuation,
                        onPress: model.pressValuation,
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
                        calculator: model.loanAmount,
                        onPress: model.pressLoanAmount,
                        onDismiss: closeLoanAmount,
                        onDone: closeLoanAmount
                    ) {
                        saveButton
                    }
                }
            }
        }
        .iconEditorDrawer(
            isPresented: $isEditingIcon,
            model: model.icon,
            focus: $focus,
            textField: .text,
            below: iconBottom
        )
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .deletionNotice($valuationDeletion) { deletion in
            Task {
                await model.restore(deletion)
            }
        }
        .confirmsUnsavedHide(
            isHidden: model.isHidden,
            canSave: model.canSave,
            isPresented: $isConfirmingHideChanges
        ) {
            Task {
                await save(hiding: true)
            }
        } onDiscard: {
            Task {
                await setHidden(!model.isHidden)
            }
        }
        .confirmsDiscard(when: model.isChanged, isPresented: $isConfirmingDiscard) {
            dismiss()
        }
        .confirmsWalletDelete(isPresented: $isConfirmingDelete) {
            Task {
                await delete()
            }
        }
        .confirmsWalletHide(balance: model.balance, isPresented: $isConfirmingHide) {
            requestHide()
        }
        .onChange(of: model.kind) {
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
            title: model.paymentQuestion,
            message: model.paymentQuestionNote,
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
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        let _ = try? database.insertDefaultsIfEmpty(at: Date())

        WalletEditSheet(model: WalletEditModel(database: database))
    }
}

import Core
import DesignSystem
import Store
import SwiftUI

extension WalletEditSheet {
    enum Field: Hashable {
        case name
        case text
    }

    enum Panel: Hashable {
        case payment
        case valuation
        case loanAmount
    }

    var title: String {
        model.isEditing ? "口座を編集" : "口座を追加"
    }

    var paymentItems: [SettingsRowList<Panel>.Item] {
        [
            .init(
                panel: .payment,
                systemImage: "repeat",
                title: model.output.paymentTitle,
                value: model.output.paymentText,
                isEmpty: model.input.payment == nil
            )
        ]
    }

    var loanAmountItem: SettingsRowList<Panel>.Item {
        .init(
            panel: .loanAmount,
            systemImage: "yensign.circle",
            title: "最初に借りた額",
            value: model.output.loanAmountText,
            detail: model.output.repaidText,
            isEmpty: model.state.loanAmount.amount == 0,
            isAmount: true
        )
    }

    var rowItems: [SettingsRowList<Panel>.Item] {
        let loan = model.output.showsLoanAmount ? [loanAmountItem] : []
        let payment = model.output.showsPayment ? paymentItems : []
        return payment + loan
    }

    var noteColor: Color {
        Color(hex: model.state.icon.color) ?? Palette.subtext
    }

    var valuationItems: [SettingsRowList<Panel>.Item] {
        let amount = isEnteringValuation ? model.state.valuation.amount : model.input.balance

        return [
            .init(
                panel: .valuation,
                systemImage: "chart.line.uptrend.xyaxis",
                title: "今の評価額",
                value: Yen.text(amount),
                isEmpty: false,
                isAmount: true
            )
        ]
    }

    var previewName: String {
        model.state.name.isEmpty ? "名前" : model.state.name
    }

    var balanceHint: String {
        switch model.state.kind {
        case .card: "まだ引き落とされていない額を、\n「払う・返す分」で入れます。"
        case .loan: "まだ返していない額を、\n「払う・返す分」で入れます。"
        default: "記録を始める前の、いまの残高を入れます。\nカードの未払いや借入は「払う・返す分」です。"
        }
    }

    var signColor: Color {
        model.state.isNegative ? Palette.rose : Palette.accentStrong
    }

    var iconStrokeWidth: CGFloat {
        isEditingIcon ? 2 : IconBadge.lineWidth
    }

    var amountStroke: Color {
        isEnteringAmount ? signColor : signColor.opacity(.muted)
    }

    func open(_ panel: Panel) {
        switch panel {
        case .payment: isEditingPayment = true
        case .valuation: openValuation()
        case .loanAmount: openLoanAmount()
        }
    }

    func openAmount() {
        focus = nil

        withAnimation(.snappy) {
            isEnteringAmount = true
        }
    }

    func closeAmount() {
        withAnimation(.snappy) {
            isEnteringAmount = false
        }
    }

    func openValuation() {
        focus = nil

        model.startValuation()

        withAnimation(.snappy) {
            isEnteringValuation = true
        }
    }

    func closeValuation() {
        withAnimation(.snappy) {
            isEnteringValuation = false
        }
    }

    func openLoanAmount() {
        focus = nil

        withAnimation(.snappy) {
            isEnteringLoanAmount = true
        }
    }

    func closeLoanAmount() {
        withAnimation(.snappy) {
            isEnteringLoanAmount = false
        }
    }

    func saveValuation() async {
        if await model.saveValuation() {
            closeValuation()
        }
    }

    func close() {
        focus = nil

        if model.isChanged {
            isConfirmingDiscard = true
        } else {
            dismiss()
        }
    }

    func save(hiding: Bool = false) async {
        focus = nil

        guard let wallet = await model.save() else {
            return
        }

        guard
            !model.isEditing,
            model.output.asksPayment
        else {
            onSave(wallet)

            if hiding {
                guard await model.setHidden(!model.input.isHidden) else {
                    return
                }

                if model.input.isHidden {
                    onHide()
                }
            }

            dismiss()

            return
        }

        addedWallet = wallet
        isAskingPayment = true
    }

    func closePayment() {
        guard addedWallet == nil else {
            finishAddedWallet()
            return
        }

        Task {
            await model.loadPayment()
        }
    }

    func finishAddedWallet() {
        guard let addedWallet else {
            return
        }

        onSave(addedWallet)
        dismiss()
    }

    func toggleHidden() {
        focus = nil

        guard !model.output.needsHideConfirmation else {
            isConfirmingHide = true
            return
        }

        requestHide()
    }

    func requestHide() {
        guard model.isChanged else {
            Task {
                await setHidden(!model.input.isHidden)
            }

            return
        }

        isConfirmingHideChanges = true
    }

    func setHidden(_ isHidden: Bool) async {
        if await model.setHidden(isHidden) {
            if isHidden {
                onHide()
            }

            dismiss()
        }
    }

    func delete() async {
        if let deletion = await model.delete() {
            onDelete(deletion)
            dismiss()
        }
    }
}

import Core
import DesignSystem
import FeatureModels
import SwiftUI

extension WalletEditSheet {
    enum Field: Hashable {
        case name
        case text
    }

    struct Layout {
        var iconBottom: CGFloat = 0
    }

    enum Panel: Hashable {
        case payment
        case valuation
        case loanAmount
    }
}

extension WalletEditSheet {
    var title: String {
        model.flow.output.isEditing ? "口座を編集" : "口座を追加"
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
            isEmpty: model.state.submodels.loanAmount.amount == 0,
            isAmount: true
        )
    }

    var rowItems: [SettingsRowList<Panel>.Item] {
        let loan = model.output.showsLoanAmount ? [loanAmountItem] : []
        let payment = model.output.showsPayment ? paymentItems : []
        return payment + loan
    }

    var noteColor: Color {
        Color(hex: model.state.submodels.icon.color) ?? Palette.subtext
    }

    var valuationItems: [SettingsRowList<Panel>.Item] {
        let isEntering = model.state.presented.panel.isShowing(.valuation)
        let amount = isEntering ? model.state.submodels.valuation.amount : model.input.balance

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
        model.state.fields.name.isEmpty ? "名前" : model.state.fields.name
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
        model.state.submodels.icon.isPresented ? 2 : IconBadge.lineWidth
    }

    var amountStroke: Color {
        model.state.presented.panel.isShowing(.amount) ? signColor : signColor.opacity(.muted)
    }

    func open(_ panel: Panel) {
        switch panel {
        case .payment: model.state.presented.paymentStep.show(.editing)
        case .valuation: openValuation()
        case .loanAmount: openLoanAmount()
        }
    }

    func openAmount() {
        focus = nil
        show(.amount)
    }

    func closeAmount() {
        show(nil)
    }

    func openValuation() {
        focus = nil
        model.startValuation()
        show(.valuation)
    }

    func closeValuation() {
        show(nil)
    }

    func openLoanAmount() {
        focus = nil
        show(.loanAmount)
    }

    func closeLoanAmount() {
        show(nil)
    }

    func show(_ drawer: WalletEditModel.Drawer?) {
        withAnimation(.snappy) {
            if let drawer {
                model.state.presented.panel.show(drawer)
            } else {
                model.state.presented.panel.closeAll()
            }
        }
    }

    func saveValuation() {
        model.perform {
            await $0.saveValuation()
        }
    }

    func closePayment() {
        guard model.state.addedWallet == nil else {
            model.finishAddedWallet()
            return
        }

        model.perform {
            await $0.loadPayment()
        }
    }

    func save() {
        focus = nil
        model.flow.save()
    }
}

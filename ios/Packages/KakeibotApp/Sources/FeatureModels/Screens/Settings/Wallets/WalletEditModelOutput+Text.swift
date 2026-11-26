import Core
import DesignSystem

public extension WalletEditModel.Output {
    var showsPayment: Bool {
        isEditing && (state.kind == .card || state.kind == .loan)
    }

    var showsValuation: Bool {
        isEditing && state.kind == .investment
    }

    var showsLoanAmount: Bool {
        state.kind == .loan
    }

    var balanceText: String {
        Yen.text(initialBalance)
    }

    var loanAmountText: String {
        state.loanAmount.amount > 0 ? Yen.text(state.loanAmount.amount) : "未入力"
    }

    var repaidText: String? {
        let borrowed = state.loanAmount.amount

        guard borrowed > 0, isEditing || state.calculator.amount > 0 else {
            return nil
        }

        let repaid = Wallet.repaid(
            borrowed: borrowed,
            balance: isEditing ? input.balance : initialBalance
        )

        let percent = Percent.floor(repaid, of: borrowed)

        return "\(Yen.text(repaid)) 返済済み（\(percent)%）"
    }

    var paymentTitle: String {
        state.kind == .loan ? "毎月の返済" : "締め日と引き落とし"
    }

    var asksPayment: Bool {
        state.kind.isDebt
    }

    var paymentQuestion: String {
        state.kind == .loan ? "毎月の返済も決めますか" : "締め日と引き落としも決めますか"
    }

    var paymentQuestionNote: String {
        state.kind == .loan ? "固定費として、返済の日と額を決められます" : "締め日までの利用分を、引き落とし日に銀行から振り替えます"
    }

    var paymentText: String {
        guard let payment = input.payment else {
            return "決めていません"
        }

        let schedule = RecurringText.schedule(
            payment.frequency,
            month: payment.month ?? payment.startDate.month,
            day: payment.day
        )

        let closing = payment.closingDay.map(RecurringText.closingNote)
        let amount = payment.amount > 0 ? Yen.text(payment.amount) : nil
        let detail = closing ?? amount

        return [schedule, detail].compactMap(\.self).joined(separator: "・")
    }
}

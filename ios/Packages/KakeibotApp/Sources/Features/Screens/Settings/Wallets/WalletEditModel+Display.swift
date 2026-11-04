import Core
import DesignSystem

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

    var canSave: Bool {
        draft.problems.isEmpty
    }

    var saveTitle: String {
        SettingsSaveTitle.text(problem: draft.problems.first?.message, isEditing: isEditing)
    }

    var showsPayment: Bool {
        isEditing && (kind == .card || kind == .loan)
    }

    var showsValuation: Bool {
        isEditing && kind == .investment
    }

    var showsLoanAmount: Bool {
        kind == .loan
    }

    var showsSign: Bool {
        !kind.isDebt
    }

    var balanceText: String {
        AmountText.text(showsSign ? calculator.amount : initialBalance)
    }

    var loanAmountText: String {
        loanAmount.amount > 0 ? AmountText.text(loanAmount.amount) : "未入力"
    }

    var repaidText: String? {
        let borrowed = loanAmount.amount

        guard borrowed > 0 else {
            return nil
        }

        guard isEditing || calculator.amount > 0 else {
            return nil
        }

        let remaining = max(-(isEditing ? balance : initialBalance), 0)
        let repaid = min(max(borrowed - remaining, 0), borrowed)
        let percent = Percent.floor(repaid, of: borrowed)

        return "\(AmountText.text(repaid)) 返済済み（\(percent)%）"
    }

    var paymentTitle: String {
        kind == .loan ? "毎月の返済" : "締め日と引き落とし"
    }

    var asksPayment: Bool {
        kind.isDebt
    }

    var paymentQuestion: String {
        kind == .loan ? "毎月の返済も決めますか" : "締め日と引き落としも決めますか"
    }

    var paymentQuestionNote: String {
        kind == .loan ? "固定費として、返済の日と額を決められます" : "締め日までの利用分を、引き落とし日に銀行から振り替えます"
    }

    var paymentText: String {
        guard let payment else {
            return "決めていません"
        }

        let schedule = RecurringText.schedule(
            payment.frequency,
            month: payment.month ?? payment.startDate.month,
            day: payment.day
        )

        let closing = payment.closingDay.map(RecurringText.closingNote)
        let amount = payment.amount > 0 ? AmountText.text(payment.amount) : nil
        let detail = closing ?? amount

        return [schedule, detail].compactMap(\.self).joined(separator: "・")
    }

    var needsHideConfirmation: Bool {
        !isHidden && totalBalance != 0
    }
}

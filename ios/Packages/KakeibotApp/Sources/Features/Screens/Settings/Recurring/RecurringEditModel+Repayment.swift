import Core
import DesignSystem
import Store

public extension RecurringEditModel {
    func prepareCount() {
        state.repayment.countCalculator = AmountCalculator(amount: output.repaymentCount ?? 0)
    }

    func pressCount(_ key: AmountCalculator.Key) {
        state.repayment.countCalculator.press(key)

        if state.repayment.countCalculator.amount > Recurring.maxCount {
            state.repayment.countCalculator = AmountCalculator(amount: Recurring.maxCount)
        }

        let count = state.repayment.countCalculator.amount
        let end = output.recurring(endDate: nil, finalAmount: nil).endDate(
            afterCount: count,
            from: output.repaymentStart
        )

        setEnd(end)
    }

    func setEnd(_ date: LocalDate?) {
        state.repayment.isCountAuto = false
        state.schedule.endDate = date
        state.repayment.manualFinal = output.manualFinalAmount(through: date)
    }

    func useAutoCount() {
        state.repayment.isCountAuto = true
        state.repayment.manualFinal = nil
    }
}

extension RecurringEditModel {
    func chooseCountMode() {
        guard output.isEditing else {
            state.repayment.isCountAuto = true
            return
        }

        guard
            let plan = output.autoPlan,
            let end = state.schedule.endDate
        else {
            state.repayment.isCountAuto = false
            return
        }

        let endsAsPlanned = output.autoEndDate(of: plan) == end
        let finalsAsPlanned = plan.finalAmount == state.repayment.manualFinal

        state.repayment.isCountAuto = endsAsPlanned && finalsAsPlanned
    }

    func loadLoanBalances() async throws {
        let list = try await dependencies.database.latestEntryList()

        let pairs = output.wallets
            .filter { $0.kind == .loan }
            .map { wallet in
                (wallet.id, list.balance(of: wallet, through: input.today))
            }

        input.loanBalances = Dictionary(uniqueKeysWithValues: pairs)
    }
}

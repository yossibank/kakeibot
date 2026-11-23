import Core
import DesignSystem
import Foundation
import Store

public extension RecurringEditModel {
    struct Repayment {
        public internal(set) var countCalculator = AmountCalculator()
        public internal(set) var isCountAuto = true
        public internal(set) var loanBalances: [Wallet.ID: Int] = [:]

        var manualFinal: Int?
        var generatedUntil: LocalDate?
    }

    var loanOwed: Int? {
        guard
            isLoanRepayment,
            let id = toWalletId,
            let balance = repayment.loanBalances[id],
            balance < 0
        else {
            return nil
        }

        return -balance
    }

    var autoPlan: RepaymentPlan? {
        loanOwed.flatMap { RepaymentPlan(owed: $0, amount: amount) }
    }

    var usesAutoCount: Bool {
        repayment.isCountAuto && autoPlan != nil
    }

    var repaymentStart: LocalDate {
        let next = repayment.generatedUntil.map { $0.adding(days: 1) } ?? startDate
        return max(startDate, next)
    }

    var scheduledEndDate: LocalDate? {
        guard
            usesAutoCount,
            let plan = autoPlan
        else {
            return endDate
        }

        return autoEndDate(of: plan)
    }

    var finalAmount: Int? {
        guard isLoanRepayment else {
            return nil
        }

        return usesAutoCount ? autoPlan?.finalAmount : repayment.manualFinal
    }

    var plannedRecurring: Recurring {
        recurring(endDate: scheduledEndDate, finalAmount: finalAmount)
    }

    var repaymentCount: Int? {
        scheduledEndDate.map { end in
            plannedRecurring.dates(from: repaymentStart, through: end).count
        }
    }

    var plannedTotal: Int? {
        let planned = plannedRecurring

        return scheduledEndDate.map { end in
            planned.dates(from: repaymentStart, through: end)
                .map(planned.scheduledAmount(paidOn:))
                .reduce(0, +)
        }
    }

    var balanceGap: Int? {
        guard
            let owed = loanOwed,
            let total = plannedTotal,
            total != owed
        else {
            return nil
        }

        return total - owed
    }

    func prepareCount() {
        repayment.countCalculator = AmountCalculator(amount: repaymentCount ?? 0)
    }

    func pressCount(_ key: AmountCalculator.Key) {
        repayment.countCalculator.press(key)

        if repayment.countCalculator.amount > Recurring.maxCount {
            repayment.countCalculator = AmountCalculator(amount: Recurring.maxCount)
        }

        let count = repayment.countCalculator.amount
        let end = recurring(endDate: nil, finalAmount: nil).endDate(
            afterCount: count,
            from: repaymentStart
        )

        setEnd(end)
    }

    func setEnd(_ date: LocalDate?) {
        repayment.isCountAuto = false
        endDate = date
        repayment.manualFinal = manualFinalAmount(through: date)
    }

    func useAutoCount() {
        repayment.isCountAuto = true
        repayment.manualFinal = nil
    }
}

extension RecurringEditModel {
    func recurring(
        endDate: LocalDate?,
        finalAmount: Int?
    ) -> Recurring {
        Recurring(
            type: type,
            amount: amount,
            categoryId: nil,
            walletId: walletId ?? Wallet.ID(),
            toWalletId: toWalletId,
            frequency: frequency,
            month: frequency == .yearly ? month : nil,
            day: day,
            holidayShift: holidayShift,
            finalAmount: finalAmount,
            startDate: startDate,
            endDate: endDate,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func autoEndDate(of plan: RepaymentPlan) -> LocalDate? {
        recurring(endDate: nil, finalAmount: nil).endDate(
            afterCount: plan.count,
            from: repaymentStart
        )
    }

    func manualFinalAmount(through end: LocalDate?) -> Int? {
        guard
            let end,
            let owed = loanOwed
        else {
            return nil
        }

        let count = recurring(endDate: end, finalAmount: nil)
            .dates(from: repaymentStart, through: end)
            .count

        return RepaymentPlan(owed: owed, amount: amount, count: count)?.finalAmount
    }

    func chooseCountMode() {
        guard isEditing else {
            repayment.isCountAuto = true
            return
        }

        guard
            let plan = autoPlan,
            let end = endDate
        else {
            repayment.isCountAuto = false
            return
        }

        let endsAsPlanned = autoEndDate(of: plan) == end
        let finalsAsPlanned = plan.finalAmount == repayment.manualFinal

        repayment.isCountAuto = endsAsPlanned && finalsAsPlanned
    }

    func loadLoanBalances() async throws {
        let list = try await database.latestEntryList()

        let pairs = wallets
            .filter { $0.kind == .loan }
            .map { wallet in
                (wallet.id, list.balance(of: wallet, through: today))
            }

        repayment.loanBalances = Dictionary(uniqueKeysWithValues: pairs)
    }
}

import Core
import Foundation
import Store

public extension RecurringEditModel.Output {
    var loanOwed: Int? {
        guard
            isLoanRepayment,
            let id = state.fields.toWalletId,
            let balance = input.loanBalances[id],
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
        state.repayment.isCountAuto && autoPlan != nil
    }

    var repaymentStart: LocalDate {
        let startDate = state.fields.schedule.startDate
        let next = input.generatedUntil.map { $0.adding(days: 1) } ?? startDate
        return max(startDate, next)
    }

    var scheduledEndDate: LocalDate? {
        guard
            usesAutoCount,
            let plan = autoPlan
        else {
            return state.fields.schedule.endDate
        }

        return autoEndDate(of: plan)
    }

    var finalAmount: Int? {
        guard isLoanRepayment else {
            return nil
        }

        return usesAutoCount ? autoPlan?.finalAmount : state.repayment.manualFinal
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
}

extension RecurringEditModel.Output {
    func recurring(
        endDate: LocalDate?,
        finalAmount: Int?
    ) -> Recurring {
        let schedule = state.fields.schedule

        return Recurring(
            type: state.type,
            amount: amount,
            categoryId: nil,
            walletId: state.fields.walletId ?? Wallet.ID(),
            toWalletId: state.fields.toWalletId,
            frequency: schedule.frequency,
            month: schedule.frequency == .yearly ? schedule.month : nil,
            day: schedule.day,
            holidayShift: schedule.holidayShift,
            finalAmount: finalAmount,
            startDate: schedule.startDate,
            endDate: endDate,
            createdAt: .distantPast,
            updatedAt: .distantPast
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
}

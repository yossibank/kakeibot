import Core
import DesignSystem
import Foundation
import Store

extension EntryModel.Output {
    struct MonthSummary {
        let overview: MonthOverview
        let budgetUsage: BudgetUsage?
        let entries: [Entry]
    }
}

public extension EntryModel.Output {
    var memoPrompt: String {
        switch state.type {
        case .expense: "店名や買ったもの"
        case .income: "どこから入ったか"
        case .transfer: "何のための移動か"
        }
    }

    var memoHint: String {
        switch state.type {
        case .expense: "店名など"
        case .income: "入金元など"
        case .transfer: "用途など"
        }
    }

    var typeName: String {
        state.type.name
    }

    var budgetUsage: BudgetUsage? {
        guard state.type == .expense else {
            return nil
        }

        return currentMonth.budgetUsage
    }

    var budgetUsageAfterSave: BudgetUsage? {
        guard let usage = budgetUsage else {
            return nil
        }

        let totals = monthTotals { $0.type == .expense }

        return BudgetUsage(
            budget: usage.baseBudget,
            carryover: usage.carryover,
            spent: usage.spent - totals.current + totals.after,
            today: state.today,
            periodEnd: monthOverview.period.upperBound
        )
    }

    var budgetNote: EntryModel.NoteLine? {
        guard
            let usage = budgetUsage,
            let after = budgetUsageAfterSave
        else {
            return nil
        }

        guard after.spent != usage.spent else {
            return EntryModel.NoteLine(
                title: usage.remainingTitle,
                value: usage.remainingAmountText
            )
        }

        let title = usage.isOver ? "予算オーバー" : "今月あと"

        let label = switch (usage.isOver, after.isOver) {
        case (false, true): "オーバー "
        case (true, false): "あと "
        default: ""
        }

        let value = "\(usage.remainingAmountText) → \(label)\(after.remainingAmountText)"

        return EntryModel.NoteLine(title: title, value: value)
    }

    var budgetText: String? {
        budgetNote.map { "\($0.title) \($0.value)" }
    }

    var monthTotalText: String? {
        let type = state.type

        guard
            type != .transfer,
            budgetUsage == nil
        else {
            return nil
        }

        let categoryId = state.category.id

        let totals = monthTotals { entry in
            entry.type == type && (categoryId == nil || entry.categoryId == categoryId)
        }

        let title = "今月の\(selectedCategory?.name ?? typeName)"

        guard totals.after != totals.current else {
            return "\(title) \(Yen.text(totals.current))"
        }

        return "\(title) \(Yen.text(totals.current)) → \(Yen.text(totals.after))"
    }

    var monthOverview: MonthOverview {
        currentMonth.overview
    }

    var saveTitle: String {
        guard !isEditing else {
            return saveAction
        }

        guard amount > 0 else {
            return "金額を入れてください"
        }

        if state.type == .transfer,
           state.payment.toWalletId == nil {
            return "\(EntryModel.destinationTitle)を選んでください"
        }

        return saveAction
    }

    func quickDate(today: LocalDate) -> LocalDate {
        state.payment.date == today ? today.adding(days: -1) : today
    }
}

extension EntryModel.Output {
    var currentMonth: MonthSummary {
        monthCache.value {
            makeMonthSummary()
        }
    }
}

private extension EntryModel.Output {
    var saveAction: String {
        switch (isEditing, state.type) {
        case (true, _): "変更を保存"
        case (false, .transfer): "振り替える"
        case (false, _): "記録する"
        }
    }

    func monthTotals(matching isIncluded: (Entry) -> Bool) -> (current: Int, after: Int) {
        let period = monthOverview.period
        let entries = currentMonth.entries.filter(isIncluded)
        let current = entries.reduce(0) { $0 + $1.amount }
        let originalId = input.original?.id
        let previous = entries.first { $0.id == originalId }?.amount ?? 0
        let added = period.contains(state.payment.date) ? amount : 0
        return (current, current - previous + added)
    }

    func makeMonthSummary() -> MonthSummary {
        let overview = MonthOverview(
            list: input.history,
            budgets: input.budgets,
            recurrings: [],
            monthStartDay: input.monthStartDay,
            carryoverFrom: input.carryoverFrom,
            today: state.today
        )

        return MonthSummary(
            overview: overview,
            budgetUsage: overview.budgetUsage,
            entries: overview.monthDays.flatMap(\.entries)
        )
    }
}

import Core
import DesignSystem
import Store

public extension BudgetListModel {
    @MainActor
    final class Output {
        let input: Input
        let state: State

        init(
            input: Input,
            state: State
        ) {
            self.input = input
            self.state = state
        }
    }
}

public extension BudgetListModel.Output {
    var recurringExpense: Int {
        let period = input.month.period(startingOn: input.monthStartDay)

        guard let entryList = input.entryList else {
            return input.recurrings.total(of: .expense, in: period)
        }

        return input.recurrings.total(of: .expense, in: period, entries: entryList.entries)
    }

    var periodText: String {
        PeriodText.range(input.month.period(startingOn: input.monthStartDay))
    }

    var categories: [EntryCategory] {
        (input.categoryList?.categories ?? []).filter { category in
            category.kind == .expense && category.archivedAt == nil
        }
    }

    var totalAmount: Int? {
        amount(for: nil)
    }

    var isCarryoverOn: Bool {
        input.carryoverFrom != nil
    }

    var carryover: Int {
        input.entryList?.budgetCarryover(
            budgets: input.budgets,
            from: input.carryoverFrom,
            into: input.month,
            startingOn: input.monthStartDay
        ) ?? 0
    }

    var categoriesTotal: Int {
        categories.compactMap { amount(for: $0.id) }.reduce(0, +)
    }

    var editingAmount: Int? {
        state.editing.flatMap { amount(for: $0.categoryId) }
    }

    var editingTitle: String {
        (state.editing ?? .total).title
    }

    var suggestions: [BudgetListModel.Suggestion] {
        guard let editing = state.editing else {
            return []
        }

        let categoryId = editing.categoryId
        let lastMonth = spent(for: categoryId, in: input.month.adding(months: -1))
        let recurring = categoryId == nil ? recurringExpense : 0
        var seen: Set<Int> = []

        let candidates = [
            BudgetListModel.Suggestion(title: "先月", amount: lastMonth),
            BudgetListModel.Suggestion(title: "3 か月の平均", amount: averageSpent(for: categoryId)),
            BudgetListModel.Suggestion(title: "固定費", amount: recurring)
        ]

        return candidates.filter { suggestion in
            suggestion.amount > 0 && seen.insert(suggestion.amount).inserted
        }
    }

    var canSave: Bool {
        state.submodels.calculator.amount > 0
    }

    var isChanged: Bool {
        state.editing != nil && state.submodels.calculator.amount != (editingAmount ?? 0)
    }

    var saveTitle: String {
        canSave ? "\(input.month.month)月からこの額にする" : "金額を入れてください"
    }

    func amount(for categoryId: EntryCategory.ID?) -> Int? {
        input.budgets.amount(for: categoryId, in: input.month)
    }

    func spent(for categoryId: EntryCategory.ID?) -> Int {
        spent(for: categoryId, in: input.month)
    }

    func spent(
        for categoryId: EntryCategory.ID?,
        in month: YearMonth
    ) -> Int {
        let period = month.period(startingOn: input.monthStartDay)

        return (input.entryList?.days.within(period) ?? [])
            .flatMap(\.entries)
            .filter { entry in
                entry.type == .expense
                    && (categoryId == nil || entry.categoryId == categoryId)
            }
            .reduce(0) { $0 + $1.amount }
    }

    func usage(for categoryId: EntryCategory.ID?) -> BudgetUsage? {
        guard let budget = amount(for: categoryId) else {
            return nil
        }

        let periodEnd = input.month.period(startingOn: input.monthStartDay).upperBound
        let carried = categoryId == nil ? carryover : 0

        return BudgetUsage(
            budget: budget,
            carryover: carried,
            spent: spent(for: categoryId),
            today: input.today,
            periodEnd: periodEnd
        )
    }

    func icon(for category: EntryCategory) -> Icon? {
        input.categoryList?.icons[category.iconId]
    }
}

private extension BudgetListModel.Output {
    static let averageMonths = 3
    static let averageUnit = 100

    func averageSpent(for categoryId: EntryCategory.ID?) -> Int {
        guard let firstDate = input.entryList?.days.map(\.date).min() else {
            return 0
        }

        let months = (1...Self.averageMonths)
            .map { input.month.adding(months: -$0) }
            .filter { $0.period(startingOn: input.monthStartDay).upperBound >= firstDate }

        guard months.count >= 2 else {
            return 0
        }

        let total = months.reduce(0) { $0 + spent(for: categoryId, in: $1) }
        let unit = months.count * Self.averageUnit

        return (total + unit - 1) / unit * Self.averageUnit
    }
}

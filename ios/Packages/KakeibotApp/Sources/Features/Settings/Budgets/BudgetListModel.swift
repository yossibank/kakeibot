import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class BudgetListModel {
    public private(set) var month: YearMonth
    public private(set) var monthStartDay: MonthStartDay = .first
    public private(set) var budgets: [Budget] = []
    public private(set) var categoryList: CategoryList?
    public private(set) var entryList: EntryList?
    public private(set) var editing: Target?
    public private(set) var calculator = AmountCalculator()
    public private(set) var recurrings: [Recurring] = []

    public internal(set) var errorNotice = ErrorNotice()

    private let database: AppDatabase
    private let today: LocalDate

    public init(
        database: AppDatabase,
        today: LocalDate
    ) {
        self.database = database
        self.today = today
        self.month = today.yearMonth
    }
}

public extension BudgetListModel {
    enum Target: Hashable, Identifiable {
        case total
        case category(EntryCategory)

        public var id: EntryCategory.ID? {
            categoryId
        }

        public var categoryId: EntryCategory.ID? {
            switch self {
            case .total: nil
            case let .category(category): category.id
            }
        }
    }

    var recurringExpense: Int {
        let period = month.period(startingOn: monthStartDay)
        return recurrings.total(of: .expense, in: period)
    }

    var periodText: String {
        PeriodText.range(month.period(startingOn: monthStartDay))
    }

    var categories: [EntryCategory] {
        let categories = categoryList?.categories ?? []

        return categories.filter { category in
            category.kind == .expense && category.archivedAt == nil
        }
    }

    var totalAmount: Int? {
        amount(for: nil)
    }

    var categoriesTotal: Int {
        categories.compactMap { amount(for: $0.id) }.reduce(0, +)
    }

    var editingAmount: Int? {
        editing.flatMap { amount(for: $0.categoryId) }
    }

    var editingTitle: String {
        switch editing {
        case let .category(category): "\(category.name)の予算"
        case .total, nil: "月全体の予算"
        }
    }

    var canSave: Bool {
        calculator.amount > 0
    }

    var saveTitle: String {
        canSave ? "\(month.month)月からこの額にする" : "金額を入れてください"
    }

    func amount(for categoryId: EntryCategory.ID?) -> Int? {
        budgets.amount(for: categoryId, in: month)
    }

    func spent(for categoryId: EntryCategory.ID?) -> Int {
        let period = month.period(startingOn: monthStartDay)
        let days = entryList?.days.filter { period.contains($0.date) } ?? []

        return days
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

        return BudgetUsage(
            budget: budget,
            spent: spent(for: categoryId),
            today: today,
            periodEnd: month.period(startingOn: monthStartDay).upperBound
        )
    }

    func icon(for category: EntryCategory) -> Icon? {
        categoryList?.icons[category.iconId]
    }

    func load() async {
        do {
            monthStartDay = try await database.setting(.monthStartDay)
            month = today.periodMonth(startingOn: monthStartDay)
            budgets = try await database.budgets()
            categoryList = try await database.categoryList()
            entryList = try await database.entryList()
            recurrings = try await database.recurrings()
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func startEditing(_ target: Target) {
        let amount = amount(for: target.categoryId) ?? 0
        calculator = AmountCalculator(amount: amount)
        editing = target
    }

    func cancelEditing() {
        editing = nil
    }

    func press(_ key: AmountCalculator.Key) {
        calculator.press(key)
    }

    func save() async {
        guard canSave else {
            return
        }

        await setBudget(calculator.amount)
    }

    func finishEditing() async {
        guard canSave, calculator.amount != editingAmount else {
            cancelEditing()
            return
        }

        await setBudget(calculator.amount)
    }

    func clear() async {
        await setBudget(nil)
    }
}

private extension BudgetListModel {
    static let loadFailedMessage = "予算を読めませんでした"
    static let saveFailedMessage = "予算を保存できませんでした"

    func setBudget(_ amount: Int?) async {
        guard let editing else {
            return
        }

        do {
            try await database.setBudget(
                amount,
                for: editing.categoryId,
                from: month
            )

            budgets = try await database.budgets()
            self.editing = nil
        } catch {
            errorNotice.show(Self.saveFailedMessage)
        }
    }
}

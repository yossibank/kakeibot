import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class BudgetListModel {
    public let state: State
    public let input: Input
    public let output: Output

    let dependencies: Dependencies

    public init(
        parts: ScreenParts,
        today: LocalDate
    ) {
        let state = State(wait: parts.wait)
        let input = Input(today: today)

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = Dependencies(database: parts.database)
    }
}

public extension BudgetListModel {
    enum Target: Hashable, Identifiable {
        case total
        case category(EntryCategory)
    }

    struct Cleared: Hashable {
        public let target: Target
        public let amount: Int
        public let month: YearMonth
    }

    struct Suggestion: Hashable {
        public let title: String
        public let amount: Int
    }

    enum Prompt: Hashable, Sendable {
        case discard
    }

    struct Presented: ScreenEditable {
        public var prompt = Shown<Prompt>()
    }

    @MainActor
    @Observable
    final class State: NoticeHolding {
        public var presented = Presented()

        public internal(set) var editing: Target?
        public internal(set) var calculator = AmountCalculator()

        public let errorNotice: ErrorNotice
        public let cleared: UndoNotice<Cleared>
        public let resetFrom: UndoNotice<YearMonth>

        init(wait: ScreenWait) {
            self.errorNotice = ErrorNotice(wait: wait)
            self.cleared = UndoNotice(wait: wait)
            self.resetFrom = UndoNotice(wait: wait)
        }
    }

    @MainActor
    @Observable
    final class Input {
        public internal(set) var month: YearMonth
        public internal(set) var monthStartDay: MonthStartDay = .first
        public internal(set) var budgets: [Budget] = []
        public internal(set) var categoryList: CategoryList?
        public internal(set) var entryList: EntryList?
        public internal(set) var recurrings: [Recurring] = []
        public internal(set) var carryoverFrom: YearMonth?

        public let hint = SettingsFoldInput.hint(.budgets)

        let today: LocalDate

        init(today: LocalDate) {
            self.today = today
            self.month = today.yearMonth
        }
    }
}

extension BudgetListModel {
    struct Dependencies {
        let database: AppDatabase
    }
}

public extension BudgetListModel {
    func load() async {
        let database = dependencies.database

        do {
            input.monthStartDay = try await database.setting(.monthStartDay)
            input.month = input.today.periodMonth(startingOn: input.monthStartDay)
            input.budgets = try await database.budgets()
            input.categoryList = try await database.categoryList()
            input.entryList = try await database.entryList()
            input.recurrings = try await database.recurrings()
            input.carryoverFrom = try await database.setting(.budgetCarryoverFrom)
        } catch {
            state.errorNotice.show(Self.loadFailedMessage)
        }
    }

    func setCarryover(_ isOn: Bool) async {
        let start = isOn ? input.month : nil
        await saveCarryoverFrom(start)
    }

    @discardableResult
    func resetCarryover() async -> YearMonth? {
        guard
            let previous = input.carryoverFrom,
            output.carryover != 0,
            await saveCarryoverFrom(input.month) else {
            state.resetFrom.dismiss()
            return nil
        }

        state.resetFrom.show(previous)

        return previous
    }

    func restoreCarryover(from start: YearMonth) async {
        await saveCarryoverFrom(start, failure: Self.restoreFailedMessage)
    }

    func startEditing(_ target: Target) {
        let amount = output.amount(for: target.categoryId) ?? 0
        state.calculator = AmountCalculator(amount: amount)
        state.editing = target
    }

    func closeEditing() {
        if output.isChanged {
            state.presented.prompt.show(.discard)
        } else {
            cancelEditing()
        }
    }

    func cancelEditing() {
        state.editing = nil

        if state.presented.prompt.isShowing(.discard) {
            state.presented.prompt.close(.discard)
        }
    }

    func save() async {
        guard output.canSave else {
            return
        }

        await setBudget(state.calculator.amount)
    }

    func finishEditing() async {
        guard
            output.canSave,
            state.calculator.amount != output.editingAmount
        else {
            cancelEditing()
            return
        }

        await setBudget(state.calculator.amount)
    }

    @discardableResult
    func clear() async -> Cleared? {
        guard
            let editing = state.editing,
            let amount = output.editingAmount,
            await setBudget(nil) else {
            return nil
        }

        let cleared = Cleared(
            target: editing,
            amount: amount,
            month: input.month
        )

        state.cleared.show(cleared)

        return cleared
    }

    func restore(_ cleared: Cleared) async {
        do {
            try await dependencies.database.setBudget(
                cleared.amount,
                for: cleared.target.categoryId,
                from: cleared.month
            )

            input.budgets = try await dependencies.database.budgets()
        } catch {
            state.errorNotice.show(Self.restoreFailedMessage, for: error)
        }
    }
}

private extension BudgetListModel {
    static let loadFailedMessage = "予算を読めませんでした"
    static let saveFailedMessage = "予算を保存できませんでした"
    static let restoreFailedMessage = "元に戻せませんでした"

    @discardableResult
    func setBudget(_ amount: Int?) async -> Bool {
        guard let editing = state.editing else {
            return false
        }

        do {
            try await dependencies.database.setBudget(
                amount,
                for: editing.categoryId,
                from: input.month
            )

            input.budgets = try await dependencies.database.budgets()
            state.editing = nil

            return true
        } catch {
            state.errorNotice.show(Self.saveFailedMessage, for: error)
            return false
        }
    }

    @discardableResult
    func saveCarryoverFrom(
        _ start: YearMonth?,
        failure: String = BudgetListModel.saveFailedMessage
    ) async -> Bool {
        do {
            try await dependencies.database.setSetting(.budgetCarryoverFrom, to: start)
            input.carryoverFrom = start
            return true
        } catch {
            state.errorNotice.show(failure, for: error)
            return false
        }
    }
}

public extension BudgetListModel.State {
    func choose(_ suggestion: BudgetListModel.Suggestion) {
        calculator = AmountCalculator(amount: suggestion.amount)
    }

    func press(_ key: AmountCalculator.Key) {
        calculator.press(key)
    }
}

public extension BudgetListModel.Target {
    var id: EntryCategory.ID? {
        categoryId
    }

    var categoryId: EntryCategory.ID? {
        switch self {
        case .total: nil
        case let .category(category): category.id
        }
    }

    var title: String {
        switch self {
        case let .category(category): "\(category.name)の予算"
        case .total: "月全体の予算"
        }
    }
}

extension BudgetListModel: SettingsFoldModel {
    public func foldStore() -> SettingsFoldStore {
        SettingsFoldStore(dependencies.database)
    }
}

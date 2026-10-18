import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class HomeModel {
    public var today: LocalDate
    public var templateType: Entry.Kind = .expense

    public private(set) var monthStartDay: MonthStartDay = .first
    public private(set) var templateOrder: TemplateOrder = .manual
    public private(set) var list: EntryList?

    public internal(set) var errorNotice = ErrorNotice()

    private var allTemplates: [EntryTemplate] = []
    private var budgets: [Budget] = []
    private var recurrings: [Recurring] = []

    private let database: AppDatabase

    public init(
        database: AppDatabase,
        today: LocalDate
    ) {
        self.database = database
        self.today = today
    }
}

public extension HomeModel {
    struct TemplateSection: Identifiable {
        public let id: EntryCategory.ID
        public let title: String
        public let templates: [EntryTemplate]
    }

    static let recentLimit = 5

    var month: YearMonth {
        today.periodMonth(startingOn: monthStartDay)
    }

    var period: ClosedRange<LocalDate> {
        month.period(startingOn: monthStartDay)
    }

    var monthRangeText: String {
        PeriodText.range(period)
    }

    var monthExpense: Int {
        monthDays.reduce(0) { $0 + $1.expenseTotal }
    }

    var recurringExpense: Int {
        recurrings.total(of: .expense, in: period)
    }

    var monthIncome: Int {
        monthDays.reduce(0) { $0 + $1.incomeTotal }
    }

    var todayExpense: Int {
        expense(on: today)
    }

    var yesterdayExpense: Int {
        expense(on: today.adding(days: -1))
    }

    var budgetUsage: BudgetUsage? {
        guard let budget = budgets.amount(for: nil, in: month) else {
            return nil
        }

        return BudgetUsage(
            budget: budget,
            spent: monthExpense,
            today: today,
            periodEnd: period.upperBound
        )
    }

    var templates: [EntryTemplate] {
        let uses = templateOrder == .frequent ? templateUses : [:]

        return allTemplates
            .filter { $0.type == templateType }
            .sorted { isOrdered($0, $1, uses: uses) }
    }

    var recentRows: [EntryRowItem] {
        guard let list else {
            return []
        }

        var rows: [EntryRowItem] = []

        for day in list.days {
            let label = dayLabel(for: day.date)

            for entry in day.entries {
                guard rows.count < Self.recentLimit else {
                    return rows
                }

                rows.append(EntryRowItem(entry, in: list, dayLabel: label))
            }
        }

        return rows
    }

    func run() async {
        await loadTemplateOrder()

        await withDiscardingTaskGroup { group in
            group.addTask {
                await self.observe()
            }

            group.addTask {
                await self.observeTemplates()
            }

            group.addTask {
                await self.observeBudgets()
            }

            group.addTask {
                await self.observeRecurrings()
            }

            group.addTask {
                await self.observeMonthStartDay()
            }
        }
    }

    func load() async {
        do {
            list = try await database.entryList()
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func loadTemplateOrder() async {
        do {
            templateOrder = try await database.setting(.templateOrder)
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func setTemplateOrder(_ order: TemplateOrder) async {
        templateOrder = order

        do {
            try await database.setSetting(.templateOrder, to: order)
        } catch {
            errorNotice.show(Self.orderSaveFailedMessage)
        }
    }

    func icon(for template: EntryTemplate) -> Icon? {
        let category = list?.categories[template.categoryId]
        return category.flatMap { list?.icons[$0.iconId] }
    }

    func templateSections(matching query: String) -> [TemplateSection] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)

        let matched = templates.filter { template in
            trimmed.isEmpty
                || template.name.localizedStandardContains(trimmed)
                || detail(for: template).localizedStandardContains(trimmed)
        }

        let categories = (list.map { Array($0.categories.values) } ?? [])
            .sorted { $0.sortOrder < $1.sortOrder }

        return categories.compactMap { category in
            let templates = matched.filter { $0.categoryId == category.id }

            guard !templates.isEmpty else {
                return nil
            }

            return TemplateSection(
                id: category.id,
                title: category.name,
                templates: templates
            )
        }
    }

    func detail(for template: EntryTemplate) -> String {
        let category = list?.categories[template.categoryId]?.name
        let tag = template.tagId.flatMap { list?.tags[$0]?.name }
        let wallet = list?.wallets[template.walletId]?.name
        let parts = [category, tag, wallet]
        return parts.compactMap(\.self).joined(separator: "・")
    }

    func record(_ template: EntryTemplate) async -> EntryChange? {
        guard let draft = template.entryDraft(on: today) else {
            return nil
        }

        do {
            let entry = try await database.saveEntry(draft, at: Date())

            return EntryChange(
                kind: .recorded,
                entry: entry,
                label: template.name
            )
        } catch {
            errorNotice.show(Self.saveFailedMessage)
            return nil
        }
    }
}

private extension HomeModel {
    static let loadFailedMessage = "記録を読めませんでした"
    static let saveFailedMessage = "記録できませんでした"
    static let orderSaveFailedMessage = "並べ順を保存できませんでした"
    static let frequentDays = 90

    var monthDays: [EntryDay] {
        list?.days.filter { period.contains($0.date) } ?? []
    }

    var templateUses: [EntryTemplate.ID: Int] {
        let start = today.adding(days: 1 - Self.frequentDays)
        let days = list?.days ?? []
        var uses: [EntryTemplate.ID: Int] = [:]

        for day in days where day.date >= start && day.date <= today {
            for case let id? in day.entries.map(\.templateId) {
                uses[id, default: 0] += 1
            }
        }

        return uses
    }

    func observe() async {
        do {
            for try await list in database.entryListUpdates() {
                self.list = list
            }
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func observeTemplates() async {
        do {
            for try await templates in database.templateUpdates() {
                allTemplates = templates
            }
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func observeRecurrings() async {
        do {
            for try await recurrings in database.recurringUpdates() {
                self.recurrings = recurrings
            }
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func observeBudgets() async {
        do {
            for try await budgets in database.budgetUpdates() {
                self.budgets = budgets
            }
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func observeMonthStartDay() async {
        do {
            for try await startDay in database.settingUpdates(.monthStartDay) {
                monthStartDay = startDay
            }
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func expense(on date: LocalDate) -> Int {
        list?.days.first { $0.date == date }?.expenseTotal ?? 0
    }

    func isOrdered(
        _ lhs: EntryTemplate,
        _ rhs: EntryTemplate,
        uses: [EntryTemplate.ID: Int]
    ) -> Bool {
        switch templateOrder {
        case .manual:
            break
        case .frequent:
            let left = uses[lhs.id, default: 0]
            let right = uses[rhs.id, default: 0]

            if left != right {
                return left > right
            }
        case .category:
            let left = categoryOrder(of: lhs)
            let right = categoryOrder(of: rhs)

            if left != right {
                return left < right
            }
        case .amount:
            let left = lhs.amount ?? -1
            let right = rhs.amount ?? -1

            if left != right {
                return left > right
            }
        case .name:
            let result = lhs.name.localizedStandardCompare(rhs.name)

            if result != .orderedSame {
                return result == .orderedAscending
            }
        }

        return lhs.sortOrder < rhs.sortOrder
    }

    func categoryOrder(of template: EntryTemplate) -> Int {
        list?.categories[template.categoryId]?.sortOrder ?? .max
    }

    func dayLabel(for date: LocalDate) -> String {
        switch date {
        case today: "今日"
        case today.adding(days: -1): "昨日"
        default: "\(date.month)/\(date.day)"
        }
    }
}

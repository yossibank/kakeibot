import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class HomeModel: ScreenModel {
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

    struct PeriodRecurring: Hashable {
        public let date: LocalDate
        public let recurring: Recurring
        public let entry: Entry?
        public let status: Status

        public var amount: Int {
            entry?.amount ?? recurring.amount
        }
    }

    enum Status: Hashable {
        case done
        case upcoming
        case missing
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

    var periodRecurrings: [PeriodRecurring] {
        let entries = list?.days
            .flatMap(\.entries)
            .filter { $0.recurringId != nil } ?? []

        return recurrings
            .flatMap { recurring in
                recurring
                    .dates(from: period.lowerBound, through: period.upperBound)
                    .map { date in
                        let entry = entries.first { entry in
                            recurring.isRecorded(by: entry, on: date)
                        }

                        return PeriodRecurring(
                            date: date,
                            recurring: recurring,
                            entry: entry,
                            status: status(of: date, entry: entry)
                        )
                    }
            }
            .sorted { $0.date < $1.date }
    }

    var recurringExpense: Int {
        recurringTotal(of: .expense)
    }

    var recurringIncome: Int {
        recurringTotal(of: .income)
    }

    var paidRecurringExpense: Int {
        recurringTotal(of: .expense) { $0 == .done }
    }

    var upcomingRecurringExpense: Int {
        recurringTotal(of: .expense) { $0 == .upcoming }
    }

    var paidRecurringRatio: Double {
        guard recurringExpense > 0 else {
            return 0
        }

        let ratio = Double(paidRecurringExpense) / Double(recurringExpense)
        return min(ratio, 1)
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
            upcoming: upcomingRecurringExpense,
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
            recurrings = try await database.recurrings()
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

    func title(of recurring: Recurring) -> String {
        list?.title(of: recurring) ?? Self.recurringTitle
    }

    func place(of recurring: Recurring) -> String? {
        list?.place(of: recurring)
    }

    func icon(of recurring: Recurring) -> Icon? {
        list?.icon(of: recurring)
    }

    func icon(for template: EntryTemplate) -> Icon? {
        list?.icon(for: template)
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
        list?.detail(for: template) ?? ""
    }

    func record(_ item: PeriodRecurring) async {
        do {
            try await database.recordRecurring(
                item.recurring.id,
                on: item.date,
                at: Date()
            )
        } catch {
            errorNotice.show(Self.saveFailedMessage)
        }
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
    static let recurringTitle = "固定費"

    func status(
        of date: LocalDate,
        entry: Entry?
    ) -> Status {
        if entry != nil {
            return .done
        }

        return date > today ? .upcoming : .missing
    }

    func recurringTotal(
        of type: Entry.Kind,
        where isIncluded: (Status) -> Bool = { _ in true }
    ) -> Int {
        periodRecurrings
            .filter { $0.recurring.type == type && isIncluded($0.status) }
            .reduce(0) { $0 + $1.amount }
    }

    var monthDays: [EntryDay] {
        list?.days.filter { period.contains($0.date) } ?? []
    }

    var templateUses: [EntryTemplate.ID: Int] {
        let start = today.adding(days: 1 - TemplateOrder.frequentDays)
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
        await observe(
            database.entryListUpdates(),
            failure: Self.loadFailedMessage
        ) { list in
            self.list = list
        }
    }

    func observeTemplates() async {
        await observe(
            database.templateUpdates(),
            failure: Self.loadFailedMessage
        ) { templates in
            allTemplates = templates
        }
    }

    func observeRecurrings() async {
        await observe(
            database.recurringUpdates(),
            failure: Self.loadFailedMessage
        ) { recurrings in
            self.recurrings = recurrings
        }
    }

    func observeBudgets() async {
        await observe(
            database.budgetUpdates(),
            failure: Self.loadFailedMessage
        ) { budgets in
            self.budgets = budgets
        }
    }

    func observeMonthStartDay() async {
        await observe(
            database.settingUpdates(.monthStartDay),
            failure: Self.loadFailedMessage
        ) { startDay in
            monthStartDay = startDay
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

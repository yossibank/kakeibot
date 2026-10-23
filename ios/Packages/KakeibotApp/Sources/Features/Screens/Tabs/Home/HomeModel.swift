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

    static let recentLimit = 5

    var overview: MonthOverview {
        MonthOverview(
            list: list,
            budgets: budgets,
            recurrings: recurrings,
            monthStartDay: monthStartDay,
            today: today
        )
    }

    var month: YearMonth {
        overview.month
    }

    var period: ClosedRange<LocalDate> {
        overview.period
    }

    var monthRangeText: String {
        PeriodText.range(period)
    }

    var monthExpense: Int {
        overview.monthExpense
    }

    var periodRecurrings: [PeriodRecurring] {
        overview.periodRecurrings
    }

    var recurringExpense: Int {
        overview.recurringExpense
    }

    var recurringIncome: Int {
        overview.recurringIncome
    }

    var paidRecurringExpense: Int {
        overview.paidRecurringExpense
    }

    var upcomingRecurringExpense: Int {
        overview.upcomingRecurringExpense
    }

    var paidRecurringRatio: Double {
        overview.paidRecurringRatio
    }

    var monthIncome: Int {
        overview.monthIncome
    }

    var todayExpense: Int {
        overview.todayExpense
    }

    var yesterdayExpense: Int {
        overview.yesterdayExpense
    }

    var budgetUsage: BudgetUsage? {
        overview.budgetUsage
    }

    var templates: [EntryTemplate] {
        let shown = allTemplates.filter { $0.type == templateType }

        guard let list else {
            return shown
        }

        return list.ordered(shown, by: templateOrder, today: today)
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

    func dayLabel(for date: LocalDate) -> String {
        switch date {
        case today: "今日"
        case today.adding(days: -1): "昨日"
        default: "\(date.month)/\(date.day)"
        }
    }
}

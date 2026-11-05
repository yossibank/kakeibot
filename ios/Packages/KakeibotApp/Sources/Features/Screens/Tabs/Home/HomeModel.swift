import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class HomeModel: ScreenModel {
    public var templateType: Entry.Kind = .expense {
        didSet {
            updateTemplates()
        }
    }

    public var today: LocalDate {
        didSet {
            updateOverview()
            updateTemplates()
        }
    }

    public private(set) var isListFailed = false
    public private(set) var templates: [EntryTemplate] = []
    public private(set) var overview: MonthOverview
    public private(set) var upcomingBills: [CardBill] = []

    public private(set) var monthStartDay: MonthStartDay = .first {
        didSet {
            updateOverview()
        }
    }

    public private(set) var templateOrder: TemplateOrder = .manual {
        didSet {
            updateTemplates()
        }
    }

    public private(set) var list: EntryList? {
        didSet {
            updateOverview()
            updateTemplates()
        }
    }

    public internal(set) var errorNotice = ErrorNotice()

    private(set) var stampCalendar: StampCalendar?

    private var homeSections = HomeSection.standard
    private var homeHiddenSections: Set<HomeSection> = []

    private var allTemplates: [EntryTemplate] = [] {
        didSet {
            updateTemplates()
        }
    }

    private var budgets: [Budget] = [] {
        didSet {
            updateOverview()
        }
    }

    private var recurrings: [Recurring] = [] {
        didSet {
            updateOverview()
        }
    }

    private var carryoverFrom: YearMonth? {
        didSet {
            updateOverview()
        }
    }

    private let database: AppDatabase

    public init(
        database: AppDatabase,
        today: LocalDate
    ) {
        self.database = database
        self.today = today

        self.overview = MonthOverview(
            list: nil,
            budgets: [],
            recurrings: [],
            monthStartDay: .first,
            today: today
        )
    }
}

public extension HomeModel {
    static let recentLimit = 5

    var showsNoRecords: Bool {
        list != nil && recentRows.isEmpty
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

                let row = EntryRowItem(entry, in: list, dayLabel: label)

                rows.append(row)
            }
        }

        return rows
    }

    var homeLayout: HomeLayout {
        HomeLayout(order: homeSections, hidden: homeHiddenSections)
    }

    var upcomingBillTotal: Int {
        upcomingBills.reduce(0) { $0 + $1.amount }
    }

    func run() async {
        await loadTemplateOrder()
        await loadHomeLayout()

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

            group.addTask {
                await self.observeCarryoverFrom()
            }

            group.addTask {
                await self.observeHomeSections()
            }

            group.addTask {
                await self.observeHomeHiddenSections()
            }

            group.addTask {
                await self.observeStamps()
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
            errorNotice.show(Self.orderSaveFailedMessage, for: error)
        }
    }

    func hide(_ section: HomeSection) async {
        var layout = homeLayout

        layout.setHidden(section, true)

        homeSections = layout.order
        homeHiddenSections = layout.hidden

        do {
            try await database.setSetting(.homeSections, to: layout.order)
            try await database.setSetting(.homeHiddenSections, to: layout.hidden)
        } catch {
            errorNotice.show(Self.layoutSaveFailedMessage, for: error)
        }
    }

    func record(_ item: PeriodRecurring) async {
        do {
            try await database.recordRecurring(
                item.recurring.id,
                on: item.date,
                at: Date()
            )
        } catch {
            errorNotice.show(Self.saveFailedMessage, for: error)
        }
    }

    func record(_ template: EntryTemplate) async -> EntryChange? {
        do {
            let recordable = try await database.entryDraft(for: template, on: today)

            guard let draft = recordable else {
                return nil
            }

            let saved = try await database.saveEntryResult(draft, at: Date())

            return EntryChange(
                kind: .recorded,
                entry: saved.entry,
                label: template.name,
                clearedNoSpendDays: saved.clearedNoSpendDays
            )
        } catch {
            errorNotice.show(Self.saveFailedMessage, for: error)
            return nil
        }
    }
}

private extension HomeModel {
    static let loadFailedMessage = "記録を読めませんでした"
    static let saveFailedMessage = "記録できませんでした"
    static let orderSaveFailedMessage = "並べ順を保存できませんでした"
    static let layoutSaveFailedMessage = "設定を保存できませんでした"

    func observe() async {
        isListFailed = false

        isListFailed = await observe(
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

    func loadHomeLayout() async {
        do {
            homeSections = try await database.setting(.homeSections)
            homeHiddenSections = try await database.setting(.homeHiddenSections)
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func observeHomeSections() async {
        await observe(
            database.settingUpdates(.homeSections),
            failure: Self.loadFailedMessage
        ) { sections in
            homeSections = sections
        }
    }

    func observeHomeHiddenSections() async {
        await observe(
            database.settingUpdates(.homeHiddenSections),
            failure: Self.loadFailedMessage
        ) { sections in
            homeHiddenSections = sections
        }
    }

    func observeStamps() async {
        await observe(
            database.stampCalendarUpdates(),
            failure: Self.loadFailedMessage
        ) { calendar in
            stampCalendar = calendar
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

    func observeCarryoverFrom() async {
        await observe(
            database.settingUpdates(.budgetCarryoverFrom),
            failure: Self.loadFailedMessage
        ) { month in
            carryoverFrom = month
        }
    }

    func updateOverview() {
        overview = MonthOverview(
            list: list,
            budgets: budgets,
            recurrings: recurrings,
            monthStartDay: monthStartDay,
            carryoverFrom: carryoverFrom,
            today: today
        )

        upcomingBills = list.map { list in
            CardBill.upcoming(
                recurrings: recurrings,
                wallets: Array(list.wallets.values),
                entries: list.days.flatMap(\.entries),
                valuations: list.valuations,
                adjustments: list.adjustments,
                after: today
            )
        } ?? []
    }

    func updateTemplates() {
        let shown = allTemplates.filter { $0.type == templateType }

        templates = list?.ordered(shown, by: templateOrder, today: today) ?? shown
    }

    func dayLabel(for date: LocalDate) -> String {
        switch date {
        case today: "今日"
        case today.adding(days: -1): "昨日"
        default: "\(date.month)/\(date.day)"
        }
    }
}

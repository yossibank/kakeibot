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

    public var billPage = 0

    public private(set) var isListFailed = false
    public private(set) var templates: [EntryTemplate] = []
    public private(set) var overview: MonthOverview
    public private(set) var billPages: [BillPage] = []
    public private(set) var syncStatus = SyncStatus.off

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

    private(set) var stampBook: StampBook?

    private var homeSections = HomeSection.standard
    private var homeHiddenSections: Set<HomeSection> = []

    private var allTemplates: [EntryTemplate] = [] {
        didSet {
            updateTemplates()
        }
    }

    private var input = Input() {
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

    var monthStartDay: MonthStartDay {
        input.monthStartDay
    }

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

    func run() async {
        await loadTemplateOrder()
        await loadHomeLayout()

        await observeAll([
            {
                await self.observe(
                    self.database.entryListUpdates(),
                    into: \.list,
                    failing: \.isListFailed
                )
            },
            {
                await self.observe(self.database.templateUpdates(), into: \.allTemplates)
            },
            {
                await self.observe(self.database.budgetUpdates(), into: \.input.budgets)
            },
            {
                await self.observe(self.database.recurringUpdates(), into: \.input.recurrings)
            },
            {
                await self.observe(
                    self.database.settingUpdates(.monthStartDay),
                    into: \.input.monthStartDay
                )
            },
            {
                await self.observe(
                    self.database.settingUpdates(.budgetCarryoverFrom),
                    into: \.input.carryoverFrom
                )
            },
            {
                await self.observe(
                    self.database.settingUpdates(.homeSections),
                    into: \.homeSections
                )
            },
            {
                await self.observe(
                    self.database.settingUpdates(.homeHiddenSections),
                    into: \.homeHiddenSections
                )
            },
            {
                await self.observe(self.database.stampBookUpdates(), into: \.stampBook)
            },
            {
                await self.observeSyncStatus()
            }
        ])
    }

    func load() async {
        do {
            list = try await database.entryList()
            input.recurrings = try await database.recurrings()
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

extension HomeModel {
    static let loadFailedMessage = "記録を読めませんでした"
}

private extension HomeModel {
    struct Input {
        var budgets: [Budget] = []
        var recurrings: [Recurring] = []
        var monthStartDay: MonthStartDay = .first
        var carryoverFrom: YearMonth?
    }

    static let saveFailedMessage = "記録できませんでした"
    static let orderSaveFailedMessage = "並べ順を保存できませんでした"
    static let layoutSaveFailedMessage = "設定を保存できませんでした"

    func loadHomeLayout() async {
        do {
            homeSections = try await database.setting(.homeSections)
            homeHiddenSections = try await database.setting(.homeHiddenSections)
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func observeSyncStatus() async {
        do {
            for try await status in database.syncStatusUpdates() {
                syncStatus = status
            }
        } catch {
            syncStatus = .off
        }
    }

    func updateOverview() {
        let bills = list?.upcomingCardBills(
            recurrings: input.recurrings,
            after: today,
            count: BillPage.limit
        )

        overview = MonthOverview(
            list: list,
            budgets: input.budgets,
            recurrings: input.recurrings,
            monthStartDay: input.monthStartDay,
            carryoverFrom: input.carryoverFrom,
            today: today
        )

        billPages = BillPage.pages(of: bills ?? [])
        billPage = BillPage.clamped(billPage, in: billPages)
    }

    func updateTemplates() {
        let shown = allTemplates.filter { $0.type == templateType }

        templates = list?.ordered(shown, by: templateOrder, today: today) ?? shown
    }

    func dayLabel(for date: LocalDate) -> String {
        switch date {
        case today: "今日"
        case today.adding(days: -1): "昨日"
        default: date.monthDayText
        }
    }
}

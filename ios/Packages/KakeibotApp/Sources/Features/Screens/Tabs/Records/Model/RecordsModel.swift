import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class RecordsModel: ScreenModel {
    public var today: LocalDate
    public var selectedDate: LocalDate?
    public var isSearching = false
    public var isConfirmingDelete = false

    public var searchText = "" {
        didSet {
            updateSearch()
        }
    }

    public var filter = EntryFilter() {
        didSet {
            updateSearch()
        }
    }

    public private(set) var month: YearMonth
    public private(set) var monthStartDay: MonthStartDay = .first
    public private(set) var weekStart: Weekday = .sunday
    public private(set) var layout: RecordsLayout = .calendar
    public private(set) var isListFailed = false
    public private(set) var noSpendDays: Set<LocalDate> = []
    public private(set) var stampCalendar: StampCalendar?
    public private(set) var stampShelf: IconShelf?
    public private(set) var rewardBank: RewardBank?
    public private(set) var recurrings: [Recurring] = []
    public private(set) var recentSearches: [String] = []
    public private(set) var pendingDeleteIDs: [Entry.ID] = []
    public private(set) var searchDays: [EntryDay] = []
    public private(set) var searchHiddenCount = 0

    public private(set) var list: EntryList? {
        didSet {
            listGeneration += 1
            searchIndex = nil
            updateSearch()
        }
    }

    public internal(set) var errorNotice = ErrorNotice()

    let database: AppDatabase

    private var listGeneration = 0

    @ObservationIgnored private var monthDaysMemo = Memo<MonthDays.Key, MonthDays>()
    @ObservationIgnored private var searchIndex: EntrySearchIndex?

    public init(
        database: AppDatabase,
        today: LocalDate
    ) {
        self.database = database
        self.today = today
        self.month = today.yearMonth
    }
}

public extension RecordsModel {
    var period: ClosedRange<LocalDate> {
        month.period(startingOn: monthStartDay)
    }

    var periodText: String {
        PeriodText.range(period)
    }

    var currentMonth: YearMonth {
        today.periodMonth(startingOn: monthStartDay)
    }

    var isCurrentMonth: Bool {
        month == currentMonth
    }

    var days: [EntryDay] {
        currentMonthDays.days
    }

    var showsNoRecords: Bool {
        list != nil && days.isEmpty
    }

    var expenseTotal: Int {
        currentMonthDays.expenseTotal
    }

    var incomeTotal: Int {
        currentMonthDays.incomeTotal
    }

    var filterTitle: String? {
        list?.title(of: filter)
    }

    var weeks: [[LocalDate?]] {
        period.weeks(startingOn: weekStart)
    }

    var shownDate: LocalDate {
        if let selectedDate,
           period.contains(selectedDate) {
            return selectedDate
        }

        return period.contains(today) ? today : period.lowerBound
    }

    var pendingDeleteCount: Int {
        pendingDeleteIDs.count
    }

    func icon(for category: EntryCategory) -> Icon? {
        list?.icons[category.iconId]
    }

    func icon(for wallet: Wallet) -> Icon? {
        list?.icons[wallet.iconId]
    }

    func rememberSearch(_ text: String) async {
        let words = EntrySearch.remembering(text, in: recentSearches)

        guard words != recentSearches else {
            return
        }

        recentSearches = words

        await saveRecentSearches()
    }

    func clearRecentSearches() async {
        recentSearches = []
        await saveRecentSearches()
    }

    func day(on date: LocalDate) -> EntryDay? {
        currentMonthDays.byDate[date]
    }

    func requestDelete(
        _ ids: [Entry.ID],
        delete: ([Entry.ID]) -> Void
    ) {
        guard ids.count >= Self.confirmDeleteThreshold else {
            delete(ids)
            return
        }

        pendingDeleteIDs = ids
        isConfirmingDelete = true
    }

    func confirmDelete(delete: ([Entry.ID]) -> Void) {
        let ids = pendingDeleteIDs
        cancelDelete()
        delete(ids)
    }

    func cancelDelete() {
        pendingDeleteIDs = []
        isConfirmingDelete = false
    }

    func rows(for day: EntryDay) -> [EntryRowItem] {
        guard let list else {
            return []
        }

        return day.entries.map { EntryRowItem($0, in: list) }
    }

    func open(_ date: LocalDate) {
        closeSearch()
        month = date.periodMonth(startingOn: monthStartDay)
        selectedDate = date
        layout = .calendar
    }

    func openCurrentMonth() {
        closeSearch()
        month = currentMonth
        selectedDate = nil
    }

    func closeSearch() {
        isSearching = false
        searchText = ""
    }

    func move(months: Int) {
        month = month.adding(months: months)
        selectedDate = nil
    }

    func loadLayout() async {
        do {
            layout = try await database.setting(.recordsLayout)
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func setLayout(_ layout: RecordsLayout) {
        self.layout = layout
    }

    func saveLayout() async {
        do {
            try await database.setSetting(.recordsLayout, to: layout)
        } catch {
            errorNotice.show(Self.saveFailedMessage, for: error)
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

    func run() async {
        await loadLayout()

        await withDiscardingTaskGroup { group in
            group.addTask {
                await self.observe()
            }

            group.addTask {
                await self.observeNoSpendDays()
            }

            group.addTask {
                await self.observeStamps()
            }

            group.addTask {
                await self.observeStampShelf()
            }

            group.addTask {
                await self.observeRewardBank()
            }

            group.addTask {
                await self.observeRecurrings()
            }

            group.addTask {
                await self.observeWeekStart()
            }

            group.addTask {
                await self.observeMonthStartDay()
            }

            group.addTask {
                await self.observeRecentSearches()
            }
        }
    }
}

extension RecordsModel {
    static let loadFailedMessage = "記録を読めませんでした"
    static let saveFailedMessage = "保存できませんでした"
}

private extension RecordsModel {
    struct MonthDays {
        struct Key: Equatable {
            let listGeneration: Int
            let month: YearMonth
            let monthStartDay: MonthStartDay
            let filter: EntryFilter
            let isSearching: Bool
        }

        let days: [EntryDay]
        let byDate: [LocalDate: EntryDay]
        let expenseTotal: Int
        let incomeTotal: Int
    }

    static let confirmDeleteThreshold = 10

    var monthDaysKey: MonthDays.Key {
        MonthDays.Key(
            listGeneration: listGeneration,
            month: month,
            monthStartDay: monthStartDay,
            filter: filter,
            isSearching: isSearching
        )
    }

    var currentMonthDays: MonthDays {
        monthDaysMemo.value(for: monthDaysKey) {
            makeMonthDays()
        }
    }

    func makeMonthDays() -> MonthDays {
        let days = makeDays()
        let byDate = Dictionary(
            days.map { ($0.date, $0) },
            uniquingKeysWith: { first, _ in
                first
            }
        )

        return MonthDays(
            days: days,
            byDate: byDate,
            expenseTotal: days.expenseTotal,
            incomeTotal: days.incomeTotal
        )
    }

    func makeDays() -> [EntryDay] {
        let days = list?.days.within(period) ?? []
        let filtered = filter.apply(to: days)
        let adjusted = adjustedDays(besides: filtered)

        guard !adjusted.isEmpty else {
            return filtered
        }

        return (filtered + adjusted).sorted { $0.date > $1.date }
    }

    func updateSearch() {
        let search = EntrySearch(searchText)

        guard
            !search.isEmpty,
            let list
        else {
            searchDays = []
            searchHiddenCount = 0
            return
        }

        let index = searchIndex ?? EntrySearchIndex(list)
        let matched = index.days(matching: search)
        let shown = filter.apply(to: matched)
        let isHidden = !filter.isEmpty && shown.isEmpty

        searchIndex = index
        searchDays = shown
        searchHiddenCount = isHidden ? Self.entryCount(in: matched) : 0
    }

    func saveRecentSearches() async {
        do {
            try await database.setSetting(.recentSearches, to: recentSearches)
        } catch {
            errorNotice.show(Self.saveFailedMessage, for: error)
        }
    }

    func observe() async {
        isListFailed = false

        isListFailed = await observe(
            database.entryListUpdates(),
            failure: Self.loadFailedMessage
        ) { list in
            self.list = list
        }
    }

    func observeNoSpendDays() async {
        await observe(
            database.noSpendDayUpdates(),
            failure: Self.loadFailedMessage
        ) { days in
            noSpendDays = days
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

    func observeStampShelf() async {
        await observe(
            database.iconShelfUpdates(),
            failure: Self.loadFailedMessage
        ) { shelf in
            stampShelf = shelf
        }
    }

    func observeRewardBank() async {
        await observe(
            database.rewardBankUpdates(),
            failure: Self.loadFailedMessage
        ) { bank in
            rewardBank = bank
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

    func observeRecentSearches() async {
        await observe(
            database.settingUpdates(.recentSearches),
            failure: Self.loadFailedMessage
        ) { words in
            recentSearches = words
        }
    }

    func observeWeekStart() async {
        await observe(
            database.settingUpdates(.weekStart),
            failure: Self.loadFailedMessage
        ) { weekStart in
            self.weekStart = weekStart
        }
    }

    func observeMonthStartDay() async {
        await observe(
            database.settingUpdates(.monthStartDay),
            failure: Self.loadFailedMessage
        ) { startDay in
            guard startDay != monthStartDay else {
                return
            }

            monthStartDay = startDay
            month = today.periodMonth(startingOn: startDay)
        }
    }
}

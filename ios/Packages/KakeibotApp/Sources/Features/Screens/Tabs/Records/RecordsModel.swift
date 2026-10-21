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
    public var searchText = ""
    public var filter = EntryFilter()

    public private(set) var month: YearMonth
    public private(set) var monthStartDay: MonthStartDay = .first
    public private(set) var weekStart: Weekday = .sunday
    public private(set) var layout: RecordsLayout = .list
    public private(set) var list: EntryList?
    public private(set) var noSpendDays: Set<LocalDate> = []
    public private(set) var stampCalendar: StampCalendar?
    public private(set) var stampShelf: IconShelf?
    public private(set) var recurrings: [Recurring] = []
    public private(set) var recentSearches: [String] = []

    public internal(set) var errorNotice = ErrorNotice()

    private let database: AppDatabase

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

    struct SearchSummary: Equatable {
        public let count: Int
        public let expenseTotal: Int
        public let incomeTotal: Int
        public let range: ClosedRange<LocalDate>
    }

    var days: [EntryDay] {
        let days = list?.days.filter { period.contains($0.date) } ?? []
        return filter.apply(to: days)
    }

    var expenseTotal: Int {
        days.reduce(0) { $0 + $1.expenseTotal }
    }

    var incomeTotal: Int {
        days.reduce(0) { $0 + $1.incomeTotal }
    }

    var searchDays: [EntryDay] {
        let search = EntrySearch(searchText)

        guard
            !search.isEmpty,
            let list
        else {
            return []
        }

        return filter.apply(to: list.days(matching: search))
    }

    var searchSummary: SearchSummary? {
        let days = searchDays

        guard
            let first = days.last?.date,
            let last = days.first?.date
        else {
            return nil
        }

        return SearchSummary(
            count: days.reduce(0) { $0 + $1.entries.count },
            expenseTotal: days.reduce(0) { $0 + $1.expenseTotal },
            incomeTotal: days.reduce(0) { $0 + $1.incomeTotal },
            range: first...last
        )
    }

    var filterTitle: String? {
        list?.title(of: filter)
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

    var weeks: [[LocalDate?]] {
        period.weeks(startingOn: weekStart)
    }

    var shownDate: LocalDate {
        if let selectedDate, period.contains(selectedDate) {
            return selectedDate
        }

        return period.contains(today) ? today : period.lowerBound
    }

    func day(on date: LocalDate) -> EntryDay? {
        days.first { $0.date == date }
    }

    var stampChoices: [Icon] {
        guard let stampShelf else {
            return []
        }

        return stampShelf.shelfIcons
            .filter { $0.archivedAt == nil }
            .compactMap { stampShelf.icons[$0.iconId] }
    }

    func upcomingRecurrings(on date: LocalDate) -> [Recurring] {
        guard date > today else {
            return []
        }

        return recurrings.filter { recurring in
            !recurring.dates(from: date, through: date).isEmpty
        }
    }

    func amount(
        of recurring: Recurring,
        on date: LocalDate
    ) -> Int {
        list?.amount(of: recurring, on: date) ?? recurring.amount
    }

    func title(of recurring: Recurring) -> String {
        list?.title(of: recurring) ?? Self.recurringTitle
    }

    func stampIcon(on date: LocalDate) -> Icon? {
        stampCalendar?.icon(on: date)
    }

    func stamp(
        _ icon: Icon,
        on date: LocalDate
    ) async {
        do {
            try await database.stamp(icon.id, on: date, at: Date())
        } catch {
            errorNotice.show(Self.saveFailedMessage)
        }
    }

    func removeStamp(on date: LocalDate) async {
        do {
            try await database.removeStamp(on: date)
        } catch {
            errorNotice.show(Self.saveFailedMessage)
        }
    }

    func canMarkNoSpend(on date: LocalDate) -> Bool {
        date <= today && (day(on: date)?.expenseTotal ?? 0) == 0
    }

    func rows(for day: EntryDay) -> [EntryRowItem] {
        guard let list else {
            return []
        }

        return day.entries.map { EntryRowItem($0, in: list) }
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

    func open(_ date: LocalDate) {
        month = date.periodMonth(startingOn: monthStartDay)
        selectedDate = date
        layout = .calendar
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
            errorNotice.show(Self.saveFailedMessage)
        }
    }

    func toggleNoSpendDay(on date: LocalDate) async {
        do {
            if noSpendDays.contains(date) {
                try await database.unmarkNoSpendDay(date)
            } else {
                try await database.markNoSpendDay(date, at: Date())
            }
        } catch {
            errorNotice.show(Self.saveFailedMessage)
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
}

private extension RecordsModel {
    static let loadFailedMessage = "記録を読めませんでした"
    static let saveFailedMessage = "保存できませんでした"
    static let recurringTitle = "固定費"

    func observe() async {
        await observe(
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

    func saveRecentSearches() async {
        do {
            try await database.setSetting(.recentSearches, to: recentSearches)
        } catch {
            errorNotice.show(Self.saveFailedMessage)
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
            monthStartDay = startDay
            month = today.periodMonth(startingOn: startDay)
        }
    }
}

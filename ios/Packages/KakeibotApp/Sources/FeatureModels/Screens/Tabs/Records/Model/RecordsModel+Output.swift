import Core
import DesignSystem
import Store

public extension RecordsModel {
    @MainActor
    final class Output {
        let input: Input
        let state: State

        private let monthDaysCache = Derived<MonthDays>()
        private let searchIndexCache = Derived<EntrySearchIndex?>()
        private let searchResultCache = Derived<SearchResult>()

        init(
            input: Input,
            state: State
        ) {
            self.input = input
            self.state = state
        }
    }
}

public extension RecordsModel.Output {
    var period: ClosedRange<LocalDate> {
        state.month.period(startingOn: input.monthStartDay)
    }

    var periodText: String {
        PeriodText.range(period)
    }

    var currentMonth: YearMonth {
        state.today.periodMonth(startingOn: input.monthStartDay)
    }

    var isCurrentMonth: Bool {
        state.month == currentMonth
    }

    var days: [EntryDay] {
        monthDays.days
    }

    var showsNoRecords: Bool {
        input.list.isLoaded && days.isEmpty
    }

    var expenseTotal: Int {
        monthDays.expenseTotal
    }

    var incomeTotal: Int {
        monthDays.incomeTotal
    }

    var filterTitle: String? {
        input.list.value?.title(of: state.filter)
    }

    var weeks: [[LocalDate?]] {
        period.weeks(startingOn: input.weekStart)
    }

    var shownDate: LocalDate {
        if let selectedDate = state.selectedDate,
           period.contains(selectedDate) {
            return selectedDate
        }

        return period.contains(state.today) ? state.today : period.lowerBound
    }

    var pendingDeleteCount: Int {
        state.pendingDeleteIDs.count
    }

    var searchDays: [EntryDay] {
        searchResult.days
    }

    var searchHiddenCount: Int {
        searchResult.hiddenCount
    }

    func icon(for category: EntryCategory) -> Icon? {
        input.list.value?.icons[category.iconId]
    }

    func icon(for wallet: Wallet) -> Icon? {
        input.list.value?.icons[wallet.iconId]
    }

    func day(on date: LocalDate) -> EntryDay? {
        monthDays.byDate[date]
    }

    func rows(for day: EntryDay) -> [EntryRowItem] {
        guard let list = input.list.value else {
            return []
        }

        return day.entries.map { EntryRowItem($0, in: list) }
    }
}

extension RecordsModel.Output {
    var shownFilter: EntryFilter {
        input.list.value?.widened(state.filter) ?? state.filter
    }

    static func entryCount(in days: [EntryDay]) -> Int {
        days.reduce(0) { $0 + $1.entries.count }
    }
}

private extension RecordsModel.Output {
    struct MonthDays {
        let days: [EntryDay]
        let byDate: [LocalDate: EntryDay]
        let expenseTotal: Int
        let incomeTotal: Int
    }

    struct SearchResult {
        let days: [EntryDay]
        let hiddenCount: Int
    }
}

private extension RecordsModel.Output {
    var monthDays: MonthDays {
        monthDaysCache.value {
            makeMonthDays()
        }
    }

    var searchResult: SearchResult {
        searchResultCache.value {
            makeSearchResult()
        }
    }

    var searchIndex: EntrySearchIndex? {
        searchIndexCache.value {
            input.list.value.map { EntrySearchIndex($0) }
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
        let days = input.list.value?.days.within(period) ?? []
        let filtered = shownFilter.apply(to: days)
        let adjusted = adjustedDays(besides: filtered)

        guard !adjusted.isEmpty else {
            return filtered
        }

        return (filtered + adjusted).sorted { $0.date > $1.date }
    }

    func makeSearchResult() -> SearchResult {
        let search = EntrySearch(state.searchText)

        guard
            !search.isEmpty,
            let index = searchIndex
        else {
            return SearchResult(days: [], hiddenCount: 0)
        }

        let matched = index.days(matching: search)
        let shown = shownFilter.apply(to: matched)
        let isHidden = !state.filter.isEmpty && shown.isEmpty

        return SearchResult(
            days: shown,
            hiddenCount: isHidden ? Self.entryCount(in: matched) : 0
        )
    }
}

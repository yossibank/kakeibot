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

    public private(set) var month: YearMonth
    public private(set) var monthStartDay: MonthStartDay = .first
    public private(set) var weekStart: Weekday = .sunday
    public private(set) var layout: RecordsLayout = .list
    public private(set) var list: EntryList?
    public private(set) var noSpendDays: Set<LocalDate> = []
    public private(set) var stampCalendar: StampCalendar?
    public private(set) var stampShelf: IconShelf?

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

    var days: [EntryDay] {
        list?.days.filter { period.contains($0.date) } ?? []
    }

    var expenseTotal: Int {
        days.reduce(0) { $0 + $1.expenseTotal }
    }

    var incomeTotal: Int {
        days.reduce(0) { $0 + $1.incomeTotal }
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
                await self.observeWeekStart()
            }

            group.addTask {
                await self.observeMonthStartDay()
            }
        }
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
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }
}

private extension RecordsModel {
    static let loadFailedMessage = "記録を読めませんでした"
    static let saveFailedMessage = "保存できませんでした"

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

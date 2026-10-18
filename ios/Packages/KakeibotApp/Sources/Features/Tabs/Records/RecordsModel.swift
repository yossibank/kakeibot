import Core
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class RecordsModel {
    public var today: LocalDate
    public var selectedDate: LocalDate?

    public private(set) var month: YearMonth
    public private(set) var monthStartDay: MonthStartDay = .first
    public private(set) var weekStart: Weekday = .sunday
    public private(set) var layout: RecordsLayout = .list
    public private(set) var list: EntryList?
    public private(set) var noSpendDays: Set<LocalDate> = []
    public private(set) var errorMessage: String?

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
            errorMessage = Self.loadFailedMessage
        }
    }

    func setLayout(_ layout: RecordsLayout) async {
        self.layout = layout

        do {
            try await database.setSetting(.recordsLayout, to: layout)
        } catch {
            errorMessage = Self.saveFailedMessage
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
            errorMessage = Self.saveFailedMessage
        }
    }

    func load() async {
        do {
            list = try await database.entryList()
        } catch {
            errorMessage = Self.loadFailedMessage
        }
    }
}

private extension RecordsModel {
    static let loadFailedMessage = "記録を読めませんでした"
    static let saveFailedMessage = "保存できませんでした"

    func observe() async {
        do {
            for try await list in database.entryListUpdates() {
                self.list = list
            }
        } catch {
            errorMessage = Self.loadFailedMessage
        }
    }

    func observeNoSpendDays() async {
        do {
            for try await days in database.noSpendDayUpdates() {
                noSpendDays = days
            }
        } catch {
            errorMessage = Self.loadFailedMessage
        }
    }

    func observeWeekStart() async {
        do {
            for try await weekStart in database.settingUpdates(.weekStart) {
                self.weekStart = weekStart
            }
        } catch {
            errorMessage = Self.loadFailedMessage
        }
    }

    func observeMonthStartDay() async {
        do {
            for try await startDay in database.settingUpdates(.monthStartDay) {
                monthStartDay = startDay
                month = today.periodMonth(startingOn: startDay)
            }
        } catch {
            errorMessage = Self.loadFailedMessage
        }
    }
}

import Core
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class RecordsModel {
    public private(set) var month: YearMonth
    public private(set) var monthStartDay: MonthStartDay = .first
    public private(set) var list: EntryList?
    public private(set) var errorMessage: String?

    private let database: AppDatabase

    public init(
        database: AppDatabase,
        month: YearMonth
    ) {
        self.database = database
        self.month = month
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

    func rows(for day: EntryDay) -> [EntryRowItem] {
        guard let list else {
            return []
        }

        return day.entries.map { EntryRowItem($0, in: list) }
    }

    func setMonthStartDay(
        _ startDay: MonthStartDay,
        today: LocalDate
    ) {
        monthStartDay = startDay
        month = today.periodMonth(startingOn: startDay)
    }

    func move(months: Int) {
        month = month.adding(months: months)
    }

    func load() async {
        do {
            list = try await database.entryList()
        } catch {
            errorMessage = Self.loadFailedMessage
        }
    }

    func observe() async {
        do {
            for try await list in database.entryListUpdates() {
                self.list = list
            }
        } catch {
            errorMessage = Self.loadFailedMessage
        }
    }
}

private extension RecordsModel {
    static let loadFailedMessage = "記録を読めませんでした"
}

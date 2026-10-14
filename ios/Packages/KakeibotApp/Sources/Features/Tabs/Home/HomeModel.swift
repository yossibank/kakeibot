import Core
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class HomeModel {
    public var today: LocalDate

    public private(set) var list: EntryList?
    public private(set) var errorMessage: String?

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
    static let recentLimit = 5

    var month: YearMonth {
        today.yearMonth
    }

    var monthRangeText: String {
        "\(month.month)/1〜\(month.month)/\(month.numberOfDays)"
    }

    var monthExpense: Int {
        monthDays.reduce(0) { $0 + $1.expenseTotal }
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

private extension HomeModel {
    static let loadFailedMessage = "記録を読めませんでした"

    var monthDays: [EntryDay] {
        list?.days.filter { $0.date.yearMonth == month } ?? []
    }

    func expense(on date: LocalDate) -> Int {
        list?.days.first { $0.date == date }?.expenseTotal ?? 0
    }

    func dayLabel(for date: LocalDate) -> String {
        switch date {
        case today: "今日"
        case today.adding(days: -1): "昨日"
        default: "\(date.month)/\(date.day)"
        }
    }
}

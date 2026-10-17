import Core
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class MonthStartDayModel {
    public private(set) var startDay: MonthStartDay = .first
    public private(set) var errorMessage: String?

    private let database: AppDatabase
    private let today: LocalDate

    public init(
        database: AppDatabase,
        today: LocalDate
    ) {
        self.database = database
        self.today = today
    }
}

public extension MonthStartDayModel {
    var month: YearMonth {
        today.periodMonth(startingOn: startDay)
    }

    var periodText: String {
        PeriodText.range(month.period(startingOn: startDay))
    }

    func load() async {
        do {
            startDay = try await database.monthStartDay()
        } catch {
            errorMessage = Self.loadFailedMessage
        }
    }

    func choose(_ startDay: MonthStartDay) async {
        let previous = self.startDay
        self.startDay = startDay

        do {
            try await database.setMonthStartDay(startDay)
        } catch {
            self.startDay = previous
            errorMessage = Self.saveFailedMessage
        }
    }
}

private extension MonthStartDayModel {
    static let loadFailedMessage = "設定を読めませんでした"
    static let saveFailedMessage = "設定を保存できませんでした"
}

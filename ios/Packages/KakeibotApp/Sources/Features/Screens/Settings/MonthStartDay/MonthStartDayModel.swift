import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class MonthStartDayModel {
    public private(set) var startDay: MonthStartDay = .first

    public internal(set) var errorNotice = ErrorNotice()

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
        let period = month.period(startingOn: startDay)
        return PeriodText.range(period)
    }

    var shiftNote: String {
        let start = month.period(startingOn: startDay).lowerBound
        let unshiftedDay = startDay.shifted(by: .none)
        let unshifted = month.period(startingOn: unshiftedDay).lowerBound

        if startDay.shift == .none {
            return "土日・祝日でも、そのまま数えます"
        }

        if start == unshifted {
            return "今の期間の始まりは、平日です"
        }

        return "\(PeriodText.weekdayDate(unshifted))を \(PeriodText.weekdayDate(start))にずらしています"
    }

    func load() async {
        do {
            startDay = try await database.setting(.monthStartDay)
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func choose(_ day: MonthStartDay) async {
        let chosen = day.shifted(by: startDay.shift)
        await save(chosen)
    }

    func choose(_ shift: HolidayShift) async {
        let chosen = startDay.shifted(by: shift)
        await save(chosen)
    }
}

private extension MonthStartDayModel {
    static let loadFailedMessage = "設定を読めませんでした"
    static let saveFailedMessage = "設定を保存できませんでした"

    func save(_ startDay: MonthStartDay) async {
        let previous = self.startDay

        self.startDay = startDay

        do {
            try await database.setSetting(.monthStartDay, to: startDay)
        } catch {
            self.startDay = previous
            errorNotice.show(Self.saveFailedMessage, for: error)
        }
    }
}

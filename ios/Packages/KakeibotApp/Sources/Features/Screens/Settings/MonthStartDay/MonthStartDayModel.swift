import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class MonthStartDayModel: SettingSaving {
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

    func hintFlag() -> SettingsScreenFlag {
        .closedHint(.monthStartDay, in: database)
    }

    func load() async {
        do {
            startDay = try await database.setting(.monthStartDay)
        } catch {
            errorNotice.show(SettingMessage.loadFailed)
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
    func save(_ startDay: MonthStartDay) async {
        let previous = self.startDay

        self.startDay = startDay

        await saveSetting(startDay, for: .monthStartDay, in: database) {
            self.startDay = previous
        }
    }
}

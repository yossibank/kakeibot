import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class MonthStartDayModel: SettingSaving {
    public let state: NoticeState
    public let input: Input
    public let output: Output

    let dependencies: Dependencies

    public init(
        parts: ScreenParts,
        today: LocalDate
    ) {
        let input = Input(today: today)

        self.state = NoticeState(wait: parts.wait)
        self.input = input
        self.output = Output(input: input)
        self.dependencies = Dependencies(database: parts.database)
    }
}

public extension MonthStartDayModel {
    @MainActor
    @Observable
    final class Input {
        public internal(set) var startDay: MonthStartDay = .first

        public let hint = SettingsFoldInput.hint(.monthStartDay)

        let today: LocalDate

        init(today: LocalDate) {
            self.today = today
        }
    }

    @MainActor
    final class Output {
        let input: Input

        init(input: Input) {
            self.input = input
        }
    }
}

extension MonthStartDayModel {
    struct Dependencies {
        let database: AppDatabase
    }
}

public extension MonthStartDayModel {
    func load() async {
        do {
            input.startDay = try await dependencies.database.setting(.monthStartDay)
        } catch {
            state.notices.error.show(SettingMessage.loadFailed)
        }
    }

    func choose(_ day: MonthStartDay) async {
        let chosen = day.shifted(by: input.startDay.shift)
        await save(chosen)
    }

    func choose(_ shift: HolidayShift) async {
        let chosen = input.startDay.shifted(by: shift)
        await save(chosen)
    }
}

private extension MonthStartDayModel {
    func save(_ startDay: MonthStartDay) async {
        let previous = input.startDay

        input.startDay = startDay

        await saveSetting(startDay, for: .monthStartDay, in: dependencies.database) {
            input.startDay = previous
        }
    }
}

public extension MonthStartDayModel.Output {
    var month: YearMonth {
        input.today.periodMonth(startingOn: input.startDay)
    }

    var periodText: String {
        let period = month.period(startingOn: input.startDay)
        return PeriodText.range(period)
    }

    var shiftNote: String {
        let startDay = input.startDay
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
}

extension MonthStartDayModel: SettingsFoldModel {
    public func foldStore() -> SettingsFoldStore {
        SettingsFoldStore(dependencies.database)
    }
}

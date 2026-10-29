import Core
import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class WeekStartModel {
    public private(set) var weekStart: Weekday = .sunday

    public internal(set) var errorNotice = ErrorNotice()

    private let database: AppDatabase

    private var savedWeekStart: Weekday = .sunday

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension WeekStartModel {
    func load() async {
        weekStart = await (try? database.setting(.weekStart)) ?? .sunday
        savedWeekStart = weekStart
    }

    func choose(_ day: Weekday) async {
        weekStart = day

        do {
            try await database.setSetting(.weekStart, to: day)
            savedWeekStart = day
        } catch {
            if weekStart == day {
                weekStart = savedWeekStart
            }

            errorNotice.show(Self.saveFailedMessage, for: error)
        }
    }
}

private extension WeekStartModel {
    static let saveFailedMessage = "設定を保存できませんでした"
}

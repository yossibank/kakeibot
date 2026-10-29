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

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension WeekStartModel {
    func load() async {
        weekStart = await (try? database.setting(.weekStart)) ?? .sunday
    }

    func choose(_ day: Weekday) async {
        let previous = weekStart

        weekStart = day

        do {
            try await database.setSetting(.weekStart, to: day)
        } catch {
            weekStart = previous
            errorNotice.show(Self.saveFailedMessage, for: error)
        }
    }
}

private extension WeekStartModel {
    static let saveFailedMessage = "設定を保存できませんでした"
}

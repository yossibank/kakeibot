import Core
import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class HomeModel: ScreenModel {
    public let state: State
    public let input: Input
    public let output: Output

    let dependencies: Dependencies

    public init(
        database: AppDatabase,
        clock: ScreenClock,
        today: LocalDate
    ) {
        let state = State(today: today)
        let input = Input()

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = Dependencies(database: database, clock: clock)
    }
}

public extension HomeModel {
    static let recentLimit = 5

    internal(set) var errorNotice: ErrorNotice {
        get {
            state.errorNotice
        }
        set {
            state.errorNotice = newValue
        }
    }
}

extension HomeModel {
    struct Dependencies {
        let database: AppDatabase
        let clock: ScreenClock
    }

    static let loadFailedMessage = "記録を読めませんでした"
    static let recurringTitle = "固定費"
}

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

    let dependencies: ScreenParts

    public init(
        parts: ScreenParts,
        today: LocalDate
    ) {
        let state = State(today: today)
        let input = Input()

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = parts
    }
}

public extension HomeModel {
    static let recentLimit = 5
}

extension HomeModel {
    public static let loadFailedMessage = "記録を読めませんでした"

    static let recurringTitle = "固定費"
}

extension HomeModel: TabScreenModel {
    public var isLoadFailed: Bool {
        false
    }

    public func setToday(_ today: LocalDate) {
        if state.today != today {
            state.today = today
        }
    }
}

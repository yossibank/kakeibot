import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class OnboardingModel {
    public let state: State
    public let input: Input
    public let output: Output

    let dependencies: Dependencies

    public init(
        database: AppDatabase,
        clock: ScreenClock,
        today: LocalDate,
        newsVersion: String
    ) {
        let state = State(
            monthStart: MonthStartDayModel(database: database, today: today),
            budget: BudgetListModel(database: database, today: today),
            setup: SetupModel(database: database, newsVersion: newsVersion)
        )

        self.state = state
        self.input = Input()
        self.output = Output(state: state)
        self.dependencies = Dependencies(database: database, clock: clock)
    }
}

public extension OnboardingModel {
    enum Page: Int, CaseIterable, Sendable {
        case welcome
        case monthStart
        case budget
        case setup
    }

    enum Route: CaseIterable, Sendable {
        case quick
        case minimal
        case full

        var pages: [Page] {
            switch self {
            case .quick: [.welcome]
            case .minimal: [.welcome, .monthStart, .budget]
            case .full: Page.allCases
            }
        }
    }

    @MainActor
    @Observable
    final class State: NoticeHolding {
        public var errorNotice = ErrorNotice()

        public internal(set) var page: Page = .welcome
        public internal(set) var route: Route?

        public let monthStart: MonthStartDayModel
        public let budget: BudgetListModel
        public let setup: SetupModel

        init(
            monthStart: MonthStartDayModel,
            budget: BudgetListModel,
            setup: SetupModel
        ) {
            self.monthStart = monthStart
            self.budget = budget
            self.setup = setup
        }
    }

    @MainActor
    @Observable
    final class Input {
        public internal(set) var weekStart: Weekday = .sunday
    }

    @MainActor
    final class Output {
        let state: State

        public var pages: [Page] {
            state.route?.pages ?? [.welcome]
        }

        public var stepPages: [Page] {
            pages.filter { $0 != .welcome }
        }

        public var isFirstPage: Bool {
            state.page == .welcome
        }

        public var isLastPage: Bool {
            state.page == pages.last
        }

        public var nextTitle: String {
            isLastPage ? "はじめる" : "次へ"
        }

        init(state: State) {
            self.state = state
        }
    }

    func load() async {
        await state.monthStart.load()
        await state.budget.load()

        do {
            try await dependencies.database.insertTemplatesIfEmpty(at: dependencies.clock.now)
            input.weekStart = try await dependencies.database.setting(.weekStart)
        } catch {
            state.errorNotice.show(Self.loadFailedMessage)
        }
    }

    func chooseWeekStart(_ weekStart: Weekday) async {
        input.weekStart = weekStart

        do {
            try await dependencies.database.setSetting(.weekStart, to: weekStart)
        } catch {
            state.errorNotice.show(Self.saveFailedMessage, for: error)
        }
    }

    func choose(_ route: Route) {
        state.route = route
    }

    func canTurn(forward: Bool) -> Bool {
        neighbor(forward: forward) != nil
    }

    func next() {
        guard let next = neighbor(forward: true) else {
            return
        }

        state.page = next
    }

    func refreshPage() async {
        if state.page == .budget {
            await state.budget.load()
        }
    }

    func back() {
        guard let previous = neighbor(forward: false) else {
            return
        }

        state.page = previous
    }

    func finish() async -> Bool {
        let version = state.setup.input.newsVersion

        do {
            let seen = try await dependencies.database.setting(.whatsNewSeenVersion)

            if AppVersion.isNewer(version, than: seen) {
                try await dependencies.database.setSetting(.whatsNewSeenVersion, to: version)
            }

            try await dependencies.database.setSetting(.onboardingCompleted, to: true)
            return true
        } catch {
            state.errorNotice.show(Self.saveFailedMessage, for: error)
            return false
        }
    }
}

extension OnboardingModel {
    struct Dependencies {
        let database: AppDatabase
        let clock: ScreenClock
    }
}

private extension OnboardingModel {
    static let loadFailedMessage = "設定を読めませんでした"
    static let saveFailedMessage = "設定を保存できませんでした"

    func neighbor(forward: Bool) -> Page? {
        let pages = output.pages

        guard let index = pages.firstIndex(of: state.page) else {
            return nil
        }

        let offset = forward ? 1 : -1
        let target = index + offset

        return pages.indices.contains(target) ? pages[target] : nil
    }
}

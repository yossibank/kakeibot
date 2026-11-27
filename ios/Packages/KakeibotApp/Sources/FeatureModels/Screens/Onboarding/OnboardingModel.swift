import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class OnboardingModel: ScreenPerforming {
    public let state: State
    public let input: Input
    public let output: Output

    let dependencies: ScreenParts

    public init(
        parts: ScreenParts,
        today: LocalDate,
        newsVersion: String
    ) {
        let state = State(
            monthStart: MonthStartDayModel(parts: parts, today: today),
            budget: BudgetListModel(parts: parts, today: today),
            setup: SetupModel(parts: parts, newsVersion: newsVersion),
            wait: parts.wait
        )

        self.state = state
        self.input = Input()
        self.output = Output(state: state)
        self.dependencies = parts
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
    }

    struct Fields: ScreenEditable {
        public var path: [SetupItem] = []

        public internal(set) var route: Route?
    }

    @MainActor
    struct Notices: ScreenNotices {
        public let error: ErrorNotice

        init(wait: ScreenWait) {
            self.error = ErrorNotice(wait: wait)
        }
    }

    @MainActor
    struct Submodels {
        public let monthStart: MonthStartDayModel
        public let budget: BudgetListModel
        public let setup: SetupModel
    }

    @MainActor
    @Observable
    final class State: NoticesHolding {
        public var fields = Fields()

        public internal(set) var outcome = ScreenOutcome<Void>()
        public internal(set) var page: Page = .welcome

        public let notices: Notices
        public let submodels: Submodels

        init(
            monthStart: MonthStartDayModel,
            budget: BudgetListModel,
            setup: SetupModel,
            wait: ScreenWait
        ) {
            self.notices = Notices(wait: wait)

            self.submodels = Submodels(
                monthStart: monthStart,
                budget: budget,
                setup: setup
            )
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

        init(state: State) {
            self.state = state
        }
    }
}

public extension OnboardingModel {
    func load() async {
        await state.submodels.monthStart.load()
        await state.submodels.budget.load()

        do {
            try await dependencies.database.insertTemplatesIfEmpty(at: dependencies.clock.now)
            input.weekStart = try await dependencies.database.setting(.weekStart)
        } catch {
            state.notices.error.show(Self.loadFailedMessage)
        }
    }

    func chooseWeekStart(_ weekStart: Weekday) async {
        input.weekStart = weekStart

        do {
            try await dependencies.database.setSetting(.weekStart, to: weekStart)
        } catch {
            state.notices.error.show(Self.saveFailedMessage, for: error)
        }
    }

    func choose(_ route: Route) {
        state.fields.route = route
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
            await state.submodels.budget.load()
        }
    }

    func back() {
        guard let previous = neighbor(forward: false) else {
            return
        }

        state.page = previous
    }

    @discardableResult
    func finish() async -> Bool {
        let version = state.submodels.setup.input.newsVersion

        do {
            let seen = try await dependencies.database.setting(.whatsNewSeenVersion)

            if AppVersion.isNewer(version, than: seen) {
                try await dependencies.database.setSetting(.whatsNewSeenVersion, to: version)
            }

            try await dependencies.database.setSetting(.onboardingCompleted, to: true)
            state.outcome.send(())

            return true
        } catch {
            state.notices.error.show(Self.saveFailedMessage, for: error)
            return false
        }
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

public extension OnboardingModel.Output {
    var pages: [OnboardingModel.Page] {
        state.fields.route?.pages ?? [.welcome]
    }

    var stepPages: [OnboardingModel.Page] {
        pages.filter { $0 != .welcome }
    }

    var isFirstPage: Bool {
        state.page == .welcome
    }

    var isLastPage: Bool {
        state.page == pages.last
    }

    var nextTitle: String {
        isLastPage ? "はじめる" : "次へ"
    }
}

public extension OnboardingModel.State {
    func open(_ item: SetupItem) {
        fields.path.append(item)
    }
}

extension OnboardingModel.Route {
    var pages: [OnboardingModel.Page] {
        switch self {
        case .quick: [.welcome]
        case .minimal: [.welcome, .monthStart, .budget]
        case .full: OnboardingModel.Page.allCases
        }
    }
}

import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class OnboardingModel {
    public private(set) var weekStart: Weekday = .sunday

    public private(set) var page: Page = .welcome
    public private(set) var route: Route?

    public internal(set) var errorNotice = ErrorNotice()

    public let monthStart: MonthStartDayModel
    public let budget: BudgetListModel
    public let setup: SetupModel

    private let database: AppDatabase

    public init(
        database: AppDatabase,
        today: LocalDate
    ) {
        self.database = database
        self.monthStart = MonthStartDayModel(database: database, today: today)
        self.budget = BudgetListModel(database: database, today: today)
        self.setup = SetupModel(database: database)
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

    var pages: [Page] {
        route?.pages ?? [.welcome]
    }

    var isFirstPage: Bool {
        page == .welcome
    }

    var isLastPage: Bool {
        page == pages.last
    }

    var nextTitle: String {
        isLastPage ? "はじめる" : "次へ"
    }

    func load() async {
        await monthStart.load()
        await budget.load()

        do {
            try await database.insertTemplatesIfEmpty(at: Date())
            try await database.setSetting(.entryStartsWithAmount, to: true)
            weekStart = try await database.setting(.weekStart)
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func chooseWeekStart(_ weekStart: Weekday) async {
        self.weekStart = weekStart

        do {
            try await database.setSetting(.weekStart, to: weekStart)
        } catch {
            errorNotice.show(Self.saveFailedMessage)
        }
    }

    func choose(_ route: Route) {
        self.route = route
    }

    func canTurn(forward: Bool) -> Bool {
        neighbor(forward: forward) != nil
    }

    func next() {
        guard let next = neighbor(forward: true) else {
            return
        }

        page = next
    }

    func refreshPage() async {
        if page == .budget {
            await budget.load()
        }
    }

    func back() {
        guard let previous = neighbor(forward: false) else {
            return
        }

        page = previous
    }

    func finish() async -> Bool {
        do {
            try await database.setSetting(.onboardingCompleted, to: true)

            return true
        } catch {
            errorNotice.show(Self.saveFailedMessage)

            return false
        }
    }
}

private extension OnboardingModel {
    static let loadFailedMessage = "設定を読めませんでした"
    static let saveFailedMessage = "設定を保存できませんでした"

    func neighbor(forward: Bool) -> Page? {
        guard let index = pages.firstIndex(of: page) else {
            return nil
        }

        let offset = forward ? 1 : -1
        let target = index + offset

        return pages.indices.contains(target) ? pages[target] : nil
    }
}

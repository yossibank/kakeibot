import Core
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class OnboardingModel {
    public var launchScreen: LaunchScreen = .home

    public private(set) var weekStart: Weekday = .sunday

    public private(set) var page: Page = .welcome
    public private(set) var isMovingForward = true
    public private(set) var errorMessage: String?

    public let monthStart: MonthStartDayModel
    public let budget: BudgetListModel

    private let database: AppDatabase

    public init(
        database: AppDatabase,
        today: LocalDate
    ) {
        self.database = database
        self.monthStart = MonthStartDayModel(database: database, today: today)
        self.budget = BudgetListModel(database: database, today: today)
    }
}

public extension OnboardingModel {
    enum Page: Int, CaseIterable, Sendable {
        case welcome
        case monthStart
        case budget
        case launchScreen
    }

    var isFirstPage: Bool {
        page == Page.allCases.first
    }

    var isLastPage: Bool {
        page == Page.allCases.last
    }

    var nextTitle: String {
        isLastPage ? "はじめる" : "次へ"
    }

    func load() async {
        await monthStart.load()
        await budget.load()

        do {
            weekStart = try await database.weekStart()
        } catch {
            errorMessage = Self.loadFailedMessage
        }
    }

    func chooseWeekStart(_ weekStart: Weekday) async {
        self.weekStart = weekStart

        do {
            try await database.setWeekStart(weekStart)
        } catch {
            errorMessage = Self.saveFailedMessage
        }
    }

    func next() {
        guard let next = Page(rawValue: page.rawValue + 1) else {
            return
        }

        isMovingForward = true
        page = next
    }

    func refreshPage() async {
        if page == .budget {
            await budget.load()
        }
    }

    func back() {
        guard let previous = Page(rawValue: page.rawValue - 1) else {
            return
        }

        isMovingForward = false
        page = previous
    }

    func finish() async -> Bool {
        do {
            try await database.setLaunchScreen(launchScreen)
            try await database.completeOnboarding()
            return true
        } catch {
            errorMessage = Self.saveFailedMessage
            return false
        }
    }
}

private extension OnboardingModel {
    static let loadFailedMessage = "設定を読めませんでした"
    static let saveFailedMessage = "設定を保存できませんでした"
}

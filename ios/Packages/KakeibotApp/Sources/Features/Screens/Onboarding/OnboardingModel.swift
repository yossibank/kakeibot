import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class OnboardingModel {
    public var launchScreen: LaunchScreen = .entry

    public private(set) var weekStart: Weekday = .sunday

    public private(set) var page: Page = .welcome

    public internal(set) var errorNotice = ErrorNotice()

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

    func canTurn(forward: Bool) -> Bool {
        let offset = forward ? 1 : -1

        return Page(rawValue: page.rawValue + offset) != nil
    }

    func next() {
        guard let next = Page(rawValue: page.rawValue + 1) else {
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
        guard let previous = Page(rawValue: page.rawValue - 1) else {
            return
        }

        page = previous
    }

    func finish() async -> Bool {
        do {
            try await database.setSetting(.launchScreen, to: launchScreen)
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
}

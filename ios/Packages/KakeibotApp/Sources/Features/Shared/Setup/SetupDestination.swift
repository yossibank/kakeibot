import Core
import FeatureModels
import SwiftUI

public struct SetupDestination: View {
    @Environment(\.notificationPermission) private var permission

    private let item: SetupItem
    private let parts: ScreenParts
    private let today: LocalDate
    private let appIcon: AppIconListModel

    public init(
        _ item: SetupItem,
        parts: ScreenParts,
        today: LocalDate,
        appIcon: AppIconListModel
    ) {
        self.item = item
        self.parts = parts
        self.today = today
        self.appIcon = appIcon
    }

    public var body: some View {
        switch item {
        case .budget: budgetList
        case .monthStart: monthStartDay
        case .wallets: WalletListView(parts: parts)
        case .categories: CategoryListView(parts: parts)
        case .recurrings: recurringList
        case .templates: TemplateListView(parts: parts)
        case .reminder: reminder
        case .launchScreen: LaunchScreenView(model: LaunchScreenModel(parts: parts))
        case .theme: ThemeListView(parts: parts, appIcon: appIcon)
        case .appIcon: AppIconListView(model: appIcon, parts: parts)
        case .themeStyle: ThemeStyleTextView(model: ThemeStyleModel(parts: parts))
        case .themeLook: ThemeStyleLookView(model: ThemeStyleModel(parts: parts))
        case .homeSections: HomeSectionListView(model: HomeSectionListModel(parts: parts))
        }
    }
}

private extension SetupDestination {
    var budgetList: some View {
        BudgetListView(
            model: BudgetListModel(
                parts: parts,
                today: today
            )
        )
    }

    var monthStartDay: some View {
        MonthStartDayView(
            model: MonthStartDayModel(
                parts: parts,
                today: today
            )
        )
    }

    var recurringList: some View {
        RecurringListView(
            board: RecurringBoard(
                parts: parts,
                today: today
            )
        )
    }

    var reminder: some View {
        ReminderView(
            model: ReminderModel(
                parts: parts,
                today: today,
                time: nil,
                permission: permission
            )
        )
    }
}

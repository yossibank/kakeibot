import Core
import Store
import SwiftUI

public struct SetupDestination: View {
    @Environment(\.notificationPermission) private var permission

    private let item: SetupItem
    private let database: AppDatabase
    private let today: LocalDate
    private let appIcon: AppIconListModel

    public init(
        _ item: SetupItem,
        database: AppDatabase,
        today: LocalDate,
        appIcon: AppIconListModel
    ) {
        self.item = item
        self.database = database
        self.today = today
        self.appIcon = appIcon
    }

    public var body: some View {
        switch item {
        case .budget:
            BudgetListView(
                model: BudgetListModel(database: database, today: today)
            )
        case .wallets:
            WalletListView(database: database)
        case .categories:
            CategoryListView(database: database)
        case .recurrings:
            RecurringListView(
                model: RecurringListModel(database: database, today: today)
            )
        case .templates:
            TemplateListView(database: database)
        case .reminder:
            ReminderView(
                model: ReminderModel(
                    database: database,
                    today: today,
                    time: nil,
                    permission: permission
                )
            )
        case .launchScreen:
            LaunchScreenView(
                model: LaunchScreenModel(database: database)
            )
        case .startsWithAmount:
            EmptyView()
        case .theme:
            ThemeListView(database: database, appIcon: appIcon)
        case .appIcon:
            AppIconListView(model: appIcon)
        case .themeStyle:
            ThemeStyleView(
                model: ThemeStyleModel(database: database)
            )
        }
    }
}

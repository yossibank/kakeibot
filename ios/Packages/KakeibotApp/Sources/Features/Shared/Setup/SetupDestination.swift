import Core
import Store
import SwiftUI

public struct SetupDestination: View {
    @State private var appIcon = AppIconListModel()

    @Environment(\.notificationPermission) private var permission

    private let item: SetupItem
    private let database: AppDatabase
    private let today: LocalDate

    public init(
        _ item: SetupItem,
        database: AppDatabase,
        today: LocalDate
    ) {
        self.item = item
        self.database = database
        self.today = today
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
        case .theme:
            ThemeListView(database: database, appIcon: appIcon)
        }
    }
}

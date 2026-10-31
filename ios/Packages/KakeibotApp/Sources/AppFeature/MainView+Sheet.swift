import Core
import Features
import Store
import SwiftUI

extension MainView {
    enum Sheet: Hashable, Identifiable {
        case new
        case edit(Entry.ID)
        case settings
        case template(EntryTemplate)
        case newTemplate
        case templates
        case transfer
        case wallet(Wallet.ID)
        case recurring(Recurring.ID)
        case periodRecurrings
        case setup(SetupItem)
        case reward

        var id: Self {
            self
        }
    }

    @ViewBuilder
    func sheetContent(for sheet: Sheet) -> some View {
        switch sheet {
        case .new:
            EntrySheet(model: draft, onChange: show)
        case let .edit(id):
            EntrySheet(
                model: EntryModel(
                    database: database,
                    editing: id,
                    date: today
                ),
                onChange: show
            )
        case .settings:
            SettingsSheet(
                database: database,
                today: today,
                appIcon: appIcon
            )
        case let .template(template):
            EntrySheet(
                model: EntryModel(
                    database: database,
                    date: today,
                    template: template
                ),
                onChange: show
            )
        case .transfer:
            EntrySheet(
                model: EntryModel(
                    database: database,
                    date: today,
                    type: .transfer
                ),
                onChange: show
            )
        case .templates:
            TemplateShelfSheet(
                model: home,
                database: database,
                onUse: useTemplate
            )
        case .newTemplate:
            TemplateEditSheet(
                model: TemplateEditModel(
                    database: database,
                    type: home.templateType
                )
            )
        case let .recurring(id):
            RecurringEditSheet(
                model: RecurringEditModel(
                    database: database,
                    today: today,
                    editing: id
                )
            ) { deletion in
                undo.deletion = deletion
            }
        case let .setup(item):
            NavigationStack {
                SetupDestination(
                    item,
                    database: database,
                    today: today,
                    appIcon: appIcon
                )
                .toolbar(.hidden, for: .navigationBar)
                .environment(\.isSettingsSheetRoot, true)
            }
        case .reward:
            RecordsRewardSheet(model: records, date: today)
        case .periodRecurrings:
            PeriodRecurringSheet(
                model: home,
                onOpenRecurring: { id in
                    self.sheet = .recurring(id)
                }
            )
        case let .wallet(id):
            WalletEditSheet(
                model: WalletEditModel(
                    database: database,
                    editing: id
                )
            ) { _ in } onDelete: { deletion in
                undo.deletion = deletion
            }
        }
    }
}

import Core
import FeatureModels
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
        case whatsNew(seenVersion: String?)

        var id: Self {
            self
        }
    }

    @ViewBuilder
    func sheetContent(for sheet: Sheet) -> some View {
        switch sheet {
        case .new:
            EntrySheet(model: draft, startsReceipt: startsReceipt, onChange: show)

        case let .edit(id):
            EntrySheet(
                model: EntryModel(
                    parts: parts,
                    editing: id,
                    date: today
                ),
                onChange: show
            )

        case .settings:
            SettingsMenuSheet(
                parts: parts,
                today: today,
                appIcon: appIcon
            )

        case let .template(template):
            EntrySheet(
                model: EntryModel(
                    parts: parts,
                    date: today,
                    template: template
                ),
                onChange: show
            )

        case .transfer:
            EntrySheet(model: draft, onChange: show)

        case .templates:
            HomeTemplateShelfSheet(
                model: home,
                parts: parts,
                onUse: useTemplate
            )

        case .newTemplate:
            TemplateEditSheet(
                model: TemplateEditModel(
                    parts: parts,
                    type: home.state.templateType
                )
            )

        case let .recurring(id):
            RecurringEditSheet(
                model: RecurringEditModel(
                    parts: parts,
                    today: today,
                    editing: id
                )
            ) { deletion in
                undo.state.deletion = deletion
            }

        case let .setup(item):
            NavigationStack {
                SetupDestination(
                    item,
                    parts: parts,
                    today: today,
                    appIcon: appIcon
                )
                .toolbar(.hidden, for: .navigationBar)
                .environment(\.isSettingsSheetRoot, true)
            }

        case .reward:
            RecordsRewardSheet(model: records, date: today)

        case let .whatsNew(seenVersion):
            WhatsNewSheet(seenVersion: seenVersion, onTry: tryFeature)

        case .periodRecurrings:
            HomeRecurringSheet(
                model: home,
                onOpenRecurring: { id in
                    self.sheet = .recurring(id)
                }
            )

        case let .wallet(id):
            WalletEditSheet(
                model: WalletEditModel(
                    parts: parts,
                    editing: id
                )
            ) { _ in } onDelete: { deletion in
                undo.state.deletion = deletion
            }
        }
    }
}

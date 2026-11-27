import Core
import FeatureModels
import Features
import SwiftUI

extension MainView {
    @ViewBuilder
    func sheetContent(for sheet: MainModel.Sheet) -> some View {
        switch sheet {
        case .new:
            EntrySheet(
                model: model.state.draft,
                startsReceipt: model.state.startsReceipt,
                onChange: show
            )

        case let .edit(id):
            editEntrySheet(id)

        case .settings:
            SettingsMenuSheet(
                parts: parts,
                today: today,
                appIcon: appIcon
            )

        case let .template(template):
            templateEntrySheet(template)

        case .transfer:
            EntrySheet(model: model.state.draft, onChange: show)

        case .templates:
            HomeTemplateShelfSheet(
                model: home,
                parts: parts,
                onUse: useTemplate
            )

        case .newTemplate:
            newTemplateSheet

        case let .recurring(id):
            recurringSheet(id)

        case let .setup(item):
            setupSheet(item)

        case .reward:
            RecordsRewardSheet(model: records, date: today)

        case let .whatsNew(seenVersion):
            WhatsNewSheet(seenVersion: seenVersion, onTry: tryFeature)

        case .periodRecurrings:
            periodRecurringsSheet

        case let .wallet(id):
            walletSheet(id)
        }
    }
}

private extension MainView {
    var newTemplateSheet: some View {
        TemplateEditSheet(
            model: TemplateEditModel(
                parts: parts,
                type: home.state.fields.templateType
            )
        )
    }

    var periodRecurringsSheet: some View {
        HomeRecurringSheet(
            model: home,
            onOpenRecurring: { id in
                model.state.presented.show(.recurring(id))
            }
        )
    }

    func editEntrySheet(_ id: Entry.ID) -> some View {
        EntrySheet(
            model: EntryModel(
                parts: parts,
                editing: id,
                date: today
            ),
            onChange: show
        )
    }

    func templateEntrySheet(_ template: EntryTemplate) -> some View {
        EntrySheet(
            model: EntryModel(
                parts: parts,
                date: today,
                template: template
            ),
            onChange: show
        )
    }

    func recurringSheet(_ id: Recurring.ID) -> some View {
        RecurringEditSheet(
            model: RecurringEditModel(
                parts: parts,
                today: today,
                editing: id
            )
        ) { deletion in
            model.receive(deletion)
        }
    }

    func setupSheet(_ item: SetupItem) -> some View {
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
    }

    func walletSheet(_ id: Wallet.ID) -> some View {
        WalletEditSheet(
            model: WalletEditModel(
                parts: parts,
                editing: id
            )
        ) { _ in } onDelete: { deletion in
            model.receive(deletion)
        }
    }
}

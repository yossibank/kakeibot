import Core
import DesignSystem
import FeatureModels
import SwiftUI

extension EntrySheet {
    @ViewBuilder
    func sheetContent(for sheet: EntryModel.Sheet) -> some View {
        switch sheet {
        case let .newWallet(role):
            WalletEditSheet(model: model.newWalletModel()) { wallet in
                model.state.noteAdded(wallet, as: role)
            }

        case let .editWallet(id):
            WalletEditSheet(model: model.editWalletModel(id)) { _ in
            } onDelete: { deletion in
                model.state.results.deletion = deletion
            }

        case .items:
            EntryItemSheet(model: model)

        case .newItem:
            EntryItemSheet(model: model, isSlipOpen: true)

        case .newCategory:
            CategoryEditSheet(model: model.newCategoryModel()) { category in
                model.perform {
                    await $0.addCategory(category.id)
                }
            }

        case let .editCategory(category):
            CategoryEditSheet(model: model.editCategoryModel(category)) { _ in
            } onDelete: { deletion in
                model.state.results.deletion = deletion
            }

        case let .addTag(category):
            CategoryEditSheet(
                model: model.editCategoryModel(category),
                startsAddingTag: true
            ) { _ in
            } onDelete: { deletion in
                model.state.results.deletion = deletion
            }

        case .newTemplate:
            TemplateEditSheet(model: model.newTemplateModel())

        case .categories:
            NavigationStack {
                CategoryListView(
                    parts: model.childParts(),
                    kind: model.output.categoryKind
                )
                .toolbar(.hidden, for: .navigationBar)
            }
        }
    }
}

extension EntrySheet {
    func open(_ sheet: EntryModel.Sheet) {
        model.state.open(sheet)
    }

    func reloadAfterSheet() {
        model.perform {
            await $0.reloadAfterSheet()
        }
    }

    func receive(_ outcome: EntryModel.Outcome) {
        switch outcome {
        case let .ready(isFirst):
            start(isFirst: isFirst)

        case let .closed(change):
            finish(change)

        case let .continued(change):
            showNext(after: change)

        case .categoryMoved:
            model.showSelectedCategory()

        case .categoryAdded:
            withAnimation(.snappy) {
                model.showSelectedCategory()
            }

        case .walletChosen:
            showTransferDeck()
        }
    }

    func receive(_ outcome: EntryReceiptFlow.Outcome) {
        if case let .read(itemCount, _) = outcome,
           itemCount > 0 {
            open(.items)
        }
    }
}

import Core
import DesignSystem
import Store
import SwiftUI

extension EntrySheet {
    @ViewBuilder
    func sheetContent(for sheet: Sheet) -> some View {
        switch sheet {
        case let .newWallet(role):
            WalletEditSheet(model: model.newWalletModel()) { wallet in
                addedWallet = AddedWallet(wallet: wallet, role: role)
            }

        case let .editWallet(id):
            WalletEditSheet(model: model.editWalletModel(id)) { _ in
            } onDelete: { deletion in
                self.deletion = deletion
            }

        case .items:
            EntryItemSheet(model: model)

        case .newItem:
            EntryItemSheet(model: model, isSlipOpen: true)

        case .newCategory:
            CategoryEditSheet(model: model.newCategoryModel()) { category in
                Task {
                    await addCategory(category)
                }
            }

        case let .editCategory(category):
            CategoryEditSheet(model: model.editCategoryModel(category)) { _ in
            } onDelete: { deletion in
                self.deletion = deletion
            }

        case let .addTag(category):
            CategoryEditSheet(
                model: model.editCategoryModel(category),
                startsAddingTag: true
            ) { _ in
            } onDelete: { deletion in
                self.deletion = deletion
            }

        case .newTemplate:
            TemplateEditSheet(model: model.newTemplateModel())

        case .categories:
            NavigationStack {
                CategoryListView(
                    database: model.database,
                    kind: model.type == .income ? .income : .expense
                )
                .toolbar(.hidden, for: .navigationBar)
            }
        }
    }
}

extension EntrySheet {
    enum Sheet: Hashable, Identifiable {
        case newWallet(EntryWalletDeck.Role)
        case editWallet(Wallet.ID)
        case items
        case newItem
        case newCategory
        case editCategory(EntryCategory)
        case addTag(EntryCategory)
        case newTemplate
        case categories

        var id: Self {
            self
        }

        var isWallet: Bool {
            switch self {
            case .newWallet, .editWallet: true
            default: false
            }
        }
    }

    struct AddedWallet {
        let wallet: Wallet
        let role: EntryWalletDeck.Role
    }

    func open(_ sheet: Sheet) {
        self.sheet = sheet

        reloadsWallets = sheet.isWallet
    }

    func reloadAfterSheet() {
        let added = addedWallet
        let needsWallets = reloadsWallets

        addedWallet = nil
        reloadsWallets = false

        Task {
            await model.reloadCategories()
            await model.reloadTemplates()

            guard needsWallets else {
                return
            }

            await model.reloadWallets()

            if let added {
                choose(added.wallet, as: added.role)
            }
        }
    }
}

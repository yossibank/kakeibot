import Core
import DesignSystem
import Store
import SwiftUI

extension EntrySheet {
    @ViewBuilder
    func sheetContent(for sheet: Sheet) -> some View {
        switch sheet {
        case let .wallet(role):
            EntryWalletSheet(model: model, role: role)
        case .date:
            EntryDateSheet(model: model, today: today)
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
        case wallet(EntryWalletSheet.Role)
        case date
        case newCategory
        case editCategory(EntryCategory)
        case addTag(EntryCategory)
        case newTemplate
        case categories

        var id: Self {
            self
        }
    }

    func open(_ sheet: Sheet) {
        setEnteringAmount(false)
        self.sheet = sheet
    }
}

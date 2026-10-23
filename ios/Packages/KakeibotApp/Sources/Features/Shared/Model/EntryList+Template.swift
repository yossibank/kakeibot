import Core
import DesignSystem
import Store

extension EntryList {
    func icon(for template: EntryTemplate) -> Icon? {
        let category = categories[template.categoryId]

        return category.flatMap { icons[$0.iconId] }
    }

    func detail(for template: EntryTemplate) -> String {
        let category = categories[template.categoryId]?.name
        let tag = template.tagId.flatMap { tags[$0]?.name }
        let wallet = wallets[template.walletId]?.name

        return [category, tag, wallet].rowDetail ?? ""
    }
}

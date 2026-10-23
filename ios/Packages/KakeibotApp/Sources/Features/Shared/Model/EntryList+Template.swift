import Core
import DesignSystem
import Store

extension EntryList {
    func detail(for template: EntryTemplate) -> String {
        let category = categories[template.categoryId]?.name
        let tag = template.tagId.flatMap { tags[$0]?.name }
        let wallet = wallets[template.walletId]?.name

        return [category, tag, wallet].rowDetail ?? ""
    }
}

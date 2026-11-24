import Core
import Store

extension EntryList {
    func searchTexts(of entry: Entry) -> [String] {
        let category = entry.categoryId.flatMap { categories[$0]?.name }
        let tag = entry.tagId.flatMap { tags[$0]?.name }
        let wallet = wallets[entry.walletId]?.name
        let toWallet = entry.toWalletId.flatMap { wallets[$0]?.name }
        let itemNames = items[entry.id, default: []].map(\.name)

        return [entry.memo, category, tag, wallet, toWallet]
            .compactMap(\.self) + itemNames
    }
}

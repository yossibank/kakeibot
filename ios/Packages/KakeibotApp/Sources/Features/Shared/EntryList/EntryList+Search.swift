import Core
import Store

extension EntryList {
    func days(matching search: EntrySearch) -> [EntryDay] {
        days.filtered { entry in
            search.matches(amount: entry.amount, texts: texts(of: entry))
        }
    }
}

private extension EntryList {
    func texts(of entry: Entry) -> [String] {
        let category = entry.categoryId.flatMap { categories[$0]?.name }
        let tag = entry.tagId.flatMap { tags[$0]?.name }
        let wallet = wallets[entry.walletId]?.name
        let toWallet = entry.toWalletId.flatMap { wallets[$0]?.name }
        let itemNames = items[entry.id, default: []].map(\.name)

        return [entry.memo, category, tag, wallet, toWallet]
            .compactMap(\.self) + itemNames
    }
}

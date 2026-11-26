import Core
import DesignSystem
import Foundation
import Store

extension EntryModel {
    struct Snapshot: Equatable {
        let type: Entry.Kind
        let calculator: AmountCalculator
        let feeCalculator: AmountCalculator
        let payment: Payment
        let categoryId: EntryCategory.ID?
        let tagId: EntryTag.ID?
        let memo: String
        let items: [EntryItem.Draft]
        let taxIncluded: Bool
    }
}

extension EntryModel {
    static let recentMemoLimit = 6
    static let recentItemNameLimit = 50

    static func message(for error: any Error) -> String {
        switch error {
        case EntryDraft.Problem.amountNotPositive: "金額を入れてください"
        case EntryDraft.Problem.missingCategory: "カテゴリを選んでください"
        case EntryDraft.Problem.missingDestination: "振替先を選んでください"
        case EntryDraft.Problem.sameWallet: "振替元と振替先を別にしてください"
        case AppDatabase.EntryWriteError.entryNotFound: "記録が見つかりませんでした"
        case _ where AppDatabase.isStorageFull(error): ErrorNotice.storageFullMessage
        default: "保存できませんでした"
        }
    }
}

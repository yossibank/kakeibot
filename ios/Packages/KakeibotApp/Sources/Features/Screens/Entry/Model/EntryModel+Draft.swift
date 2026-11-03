import Core
import DesignSystem
import Foundation
import Store

extension EntryModel {
    struct Snapshot: Equatable {
        let type: Entry.Kind
        let calculator: AmountCalculator
        let feeCalculator: AmountCalculator
        let date: LocalDate
        let categoryId: EntryCategory.ID?
        let tagId: EntryTag.ID?
        let walletId: Wallet.ID?
        let toWalletId: Wallet.ID?
        let memo: String
        let billMonth: YearMonth?
        let items: [EntryItem.Draft]
        let taxIncluded: Bool
    }

    static let recentMemoLimit = 6
    static let recentItemNameLimit = 50

    var snapshot: Snapshot {
        Snapshot(
            type: type,
            calculator: calculator,
            feeCalculator: feeCalculator,
            date: date,
            categoryId: categoryId,
            tagId: tagId,
            walletId: walletId,
            toWalletId: toWalletId,
            memo: memo,
            billMonth: billMonth,
            items: items,
            taxIncluded: taxIncluded
        )
    }

    var draft: EntryDraft? {
        guard let walletId else {
            return nil
        }

        let templateId = allTemplates
            .first { $0.id == appliedTemplateId && $0.type == type }?
            .id

        let billMonth = billChoices.isEmpty ? nil : billMonth

        return EntryDraft(
            type: type,
            amount: amount,
            date: date,
            categoryId: categoryId,
            tagId: tagId,
            templateId: templateId,
            walletId: walletId,
            toWalletId: toWalletId,
            memo: memo,
            billMonth: billMonth,
            fee: fee,
            items: showsItems ? items : [],
            taxIncluded: taxIncluded
        )
    }

    static func message(for error: any Error) -> String {
        switch error {
        case EntryDraft.Problem.amountNotPositive: "金額を入れてください"
        case EntryDraft.Problem.missingCategory: "カテゴリを選んでください"
        case EntryDraft.Problem.missingDestination: "振替先を選んでください"
        case EntryDraft.Problem.sameWallet: "振替元と振替先を別にしてください"
        case AppDatabase.WriteError.entryNotFound: "記録が見つかりませんでした"
        case _ where AppDatabase.isStorageFull(error): ErrorNotice.storageFullMessage
        default: "保存できませんでした"
        }
    }

    func label(for entry: Entry) -> String {
        let categories = categories(for: entry.type)

        return EntryChange.label(for: entry) { id in
            categories.first { $0.id == id }
        } wallet: { id in
            wallet(id)
        }
    }
}

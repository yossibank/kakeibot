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
    static let recentMemoLimit = 50
    static let recentItemNameLimit = 50
    static let memoSuggestionLimit = 6

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

    static func suggestions(
        from recent: [String],
        for text: String,
        limit: Int
    ) -> [String] {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            return Array(recent.prefix(limit))
        }

        let key = suggestionKey(text)

        let matches: [(name: String, isPrefix: Bool)] = recent.compactMap { name in
            let nameKey = suggestionKey(name)

            guard
                name != text,
                let range = nameKey.range(of: key, options: suggestionOptions)
            else {
                return nil
            }

            return (name, range.lowerBound == nameKey.startIndex)
        }

        let ordered = matches.filter(\.isPrefix) + matches.filter { !$0.isPrefix }

        return Array(ordered.prefix(limit).map(\.name))
    }
}

private extension EntryModel {
    static let suggestionOptions: String.CompareOptions = [
        .caseInsensitive,
        .diacriticInsensitive,
        .widthInsensitive
    ]

    static func suggestionKey(_ text: String) -> String {
        text.applyingTransform(.hiraganaToKatakana, reverse: false) ?? text
    }
}

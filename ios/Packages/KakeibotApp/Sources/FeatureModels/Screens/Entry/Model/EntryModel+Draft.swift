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
        let others = recent.filter { $0 != text }

        let matches: [(name: String, isPrefix: Bool)] = others.compactMap { name in
            let nameKey = suggestionKey(name)

            if let range = nameKey.range(of: key, options: suggestionOptions) {
                return (name, range.lowerBound == nameKey.startIndex)
            }

            let reading = reading(of: name)

            guard let range = reading.range(of: key, options: suggestionOptions) else {
                return nil
            }

            return (name, range.lowerBound == reading.startIndex)
        }

        guard !matches.isEmpty else {
            return Array(others.prefix(limit))
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

    static func reading(of text: String) -> String {
        let source = text as CFString
        let range = CFRange(location: 0, length: CFStringGetLength(source))
        let locale = Locale(identifier: "ja_JP") as CFLocale

        let tokenizer = CFStringTokenizerCreate(
            nil,
            source,
            range,
            kCFStringTokenizerUnitWordBoundary,
            locale
        )

        var sounds: [String] = []

        while !CFStringTokenizerAdvanceToNextToken(tokenizer).isEmpty {
            let attribute = kCFStringTokenizerAttributeLatinTranscription
            let sound = CFStringTokenizerCopyCurrentTokenAttribute(tokenizer, attribute) as? String
            sounds.append(sound ?? "")
        }

        let latin = sounds.joined()

        return latin.applyingTransform(.latinToKatakana, reverse: false) ?? latin
    }
}

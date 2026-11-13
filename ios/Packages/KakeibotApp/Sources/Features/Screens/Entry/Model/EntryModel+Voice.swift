import Core
import Foundation

public extension EntryModel {
    struct VoiceFilled: Equatable, Sendable {
        var walletId: Wallet.ID?
        var date: LocalDate?
        var memo: String?
    }

    struct VoiceUndo: Equatable {
        let calculator: AmountCalculator
        let date: LocalDate
        let categoryId: EntryCategory.ID?
        let tagId: EntryTag.ID?
        let walletId: Wallet.ID?
        let billMonth: YearMonth?
        let memo: String
    }

    var showsVoice: Bool {
        type != .transfer && keypadTarget == .amount
    }

    var isWalletFromVoice: Bool {
        voiceFilled?.walletId.map { $0 == walletId } ?? false
    }

    var isDateFromVoice: Bool {
        voiceFilled?.date.map { $0 == date } ?? false
    }

    var isMemoFromVoice: Bool {
        voiceFilled?.memo.map { !$0.isEmpty && $0 == store } ?? false
    }

    var voiceHints: [String] {
        let tags = ((options?.tags ?? []) + (options?.sharedTags ?? []))
            .filter { $0.archivedAt == nil }
            .map(\.name)

        let memos: [String] = recentMemos.compactMap { memo in
            memo.split(whereSeparator: \.isNewline).first.map(String.init)
        }

        var names: [String] = categories.map(\.name)
        names += tags
        names += wallets.map(\.name)
        names += allTemplates.map(\.name)
        names += memos

        return Self.distinct(names)
    }

    func voiceExamples(for text: String) -> [String] {
        let spoken = Self.voicePairs(of: text)

        let entries = (history?.entries ?? [])
            .filter { $0.type == type }
            .sorted { $0.createdAt > $1.createdAt }

        let similar = entries
            .map { entry in
                (entry, Self.voicePairs(of: entry.memo ?? "").intersection(spoken).count)
            }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .map(\.0)

        var seen: Set<String> = []
        var examples: [String] = []

        for entry in similar + entries where examples.count < Self.voiceExampleLimit {
            guard
                let memo = entry.memo?.split(whereSeparator: \.isNewline).first.map(String.init),
                !memo.isEmpty,
                seen.insert(memo).inserted,
                let categoryId = entry.categoryId,
                let category = history?.categories[categoryId],
                let wallet = wallets.first(where: { $0.id == entry.walletId })
            else {
                continue
            }

            examples.append("\(memo) → カテゴリ：\(category.name)、口座：\(wallet.name)")
        }

        return examples
    }

    func voiceReading(
        from text: String,
        today: LocalDate,
        choice: VoiceReading.Choice?
    ) -> VoiceReading {
        VoiceReading(
            text: text,
            today: today,
            categories: categories,
            wallets: wallets,
            choice: choice
        )
    }

    @discardableResult
    func apply(_ reading: VoiceReading) -> VoiceUndo {
        let undo = VoiceUndo(
            calculator: calculator,
            date: date,
            categoryId: categoryId,
            tagId: tagId,
            walletId: walletId,
            billMonth: billMonth,
            memo: memo
        )

        if let amount = reading.amount,
           (1...AmountCalculator.maxValue).contains(amount) {
            calculator = AmountCalculator(amount: amount)
            keypadTarget = .amount
        }

        if let walletId = reading.walletId {
            self.walletId = walletId
        }

        if let categoryId = reading.categoryId,
           categories.contains(where: { $0.id == categoryId }) {
            self.categoryId = categoryId
        }

        if let date = reading.date {
            self.date = date
        }

        if let memo = reading.memo {
            store = memo
        }

        voiceFilled = VoiceFilled(
            walletId: reading.walletId,
            date: reading.date,
            memo: reading.memo
        )

        return undo
    }

    func undo(_ undo: VoiceUndo) {
        walletId = undo.walletId
        categoryId = undo.categoryId
        tagId = undo.tagId
        calculator = undo.calculator
        date = undo.date
        billMonth = undo.billMonth
        memo = undo.memo
        voiceFilled = nil
    }
}

private extension EntryModel {
    static let voiceExampleLimit = 8

    static func voicePairs(of text: String) -> Set<String> {
        let letters = Array(text.lowercased().filter(\.isLetter))

        guard letters.count > 1 else {
            return Set(letters.map(String.init))
        }

        return Set(zip(letters, letters.dropFirst()).map { "\($0)\($1)" })
    }

    static func distinct(_ names: [String]) -> [String] {
        var seen: Set<String> = []

        return names
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && seen.insert($0).inserted }
    }
}

import Core
import Foundation

public extension EntryModel.Output {
    var showsVoice: Bool {
        state.type != .transfer && state.keypad.target == .amount
    }

    var isWalletFromVoice: Bool {
        state.filled.voice?.walletId.map { $0 == state.payment.walletId } ?? false
    }

    var isDateFromVoice: Bool {
        state.filled.voice?.date.map { $0 == state.payment.date } ?? false
    }

    var isMemoFromVoice: Bool {
        state.filled.voice?.memo.map { !$0.isEmpty && $0 == state.fields.store } ?? false
    }

    var voiceHints: [String] {
        let tags = allTags
            .filter { $0.archivedAt == nil }
            .map(\.name)

        let recentMemos = input.recentMemos.prefix(EntryModel.memoSuggestionLimit)

        let memos: [String] = recentMemos.compactMap { memo in
            memo.split(whereSeparator: \.isNewline).first.map(String.init)
        }

        var names: [String] = categories.map(\.name)

        names += tags
        names += wallets.map(\.name)
        names += input.allTemplates.map(\.name)
        names += memos

        return Self.distinct(names)
    }

    func voiceExamples(for text: String) -> [String] {
        let spoken = Self.voicePairs(of: text)
        let type = state.type

        let entries = (input.history?.entries ?? [])
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
                let category = input.history?.categories[categoryId],
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
}

private extension EntryModel.Output {
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

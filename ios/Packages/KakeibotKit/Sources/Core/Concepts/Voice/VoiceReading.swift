import Foundation

public struct VoiceReading: Equatable, Sendable {
    public var amount: Int?
    public var date: LocalDate?
    public var categoryId: EntryCategory.ID?
    public var walletId: Wallet.ID?
    public var memo: String?

    public init(
        amount: Int? = nil,
        date: LocalDate? = nil,
        categoryId: EntryCategory.ID? = nil,
        walletId: Wallet.ID? = nil,
        memo: String? = nil
    ) {
        self.amount = amount
        self.date = date
        self.categoryId = categoryId
        self.walletId = walletId
        self.memo = memo
    }
}

public extension VoiceReading {
    struct Choice: Equatable, Sendable {
        public var categoryIndex: Int?
        public var walletIndex: Int?

        public init(
            categoryIndex: Int?,
            walletIndex: Int?
        ) {
            self.categoryIndex = categoryIndex
            self.walletIndex = walletIndex
        }
    }

    var count: Int {
        let fields: [Any?] = [amount, date, categoryId, walletId, memo]
        return fields.count { $0 != nil }
    }

    var isEmpty: Bool {
        count == 0
    }

    init(
        text: String,
        today: LocalDate,
        categories: [EntryCategory],
        wallets: [Wallet],
        choice: Choice? = nil
    ) {
        let spoken = VoiceText(text)
        let date = spoken.date(today: today)
        let amount = spoken.amount(skipping: date?.range)
        let category = Self.pick(categories, at: choice?.categoryIndex, in: spoken, name: \.name)
        let wallet = Self.pick(wallets, at: choice?.walletIndex, in: spoken, name: \.name)

        let walletRange = wallet.flatMap { spoken.range(of: $0.name) }
        let used = [date?.range, amount?.range, walletRange].compactMap(\.self)

        self.init(
            amount: amount?.value,
            date: date?.value,
            categoryId: category?.id,
            walletId: wallet?.id,
            memo: spoken.memo(removing: used)
        )
    }
}

private extension VoiceReading {
    static func pick<Item>(
        _ items: [Item],
        at index: Int?,
        in spoken: VoiceText,
        name: KeyPath<Item, String>
    ) -> Item? {
        if let index, items.indices.contains(index) {
            return items[index]
        }

        return items
            .filter { spoken.contains($0[keyPath: name]) }
            .max { $0[keyPath: name].count < $1[keyPath: name].count }
    }
}

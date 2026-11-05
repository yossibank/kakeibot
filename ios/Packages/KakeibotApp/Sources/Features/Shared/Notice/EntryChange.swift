import Core
import DesignSystem
import Foundation

public struct EntryChange: Hashable, Sendable {
    public let kind: Kind
    public let entry: Entry
    public let label: String
    public let fee: Entry?
    public let clearedNoSpendDays: [NoSpendDay]
    public let items: [EntryItem]

    public init(
        kind: Kind,
        entry: Entry,
        label: String,
        fee: Entry? = nil,
        clearedNoSpendDays: [NoSpendDay] = [],
        items: [EntryItem] = []
    ) {
        self.kind = kind
        self.entry = entry
        self.label = label
        self.fee = fee
        self.clearedNoSpendDays = clearedNoSpendDays
        self.items = items
    }
}

public extension EntryChange {
    enum Kind: Hashable, Sendable {
        case recorded
        case edited(previous: Entry, previousFee: Entry?)
        case deleted
    }

    var isDeletion: Bool {
        kind == .deleted
    }

    var subject: String {
        guard isDeletion else {
            return label
        }

        let memo = entry.memo?
            .split(whereSeparator: \.isNewline)
            .first?
            .trimmingCharacters(in: .whitespaces) ?? ""

        if !memo.isEmpty {
            return memo
        }

        return label.isEmpty ? "記録" : label
    }

    var amountText: String {
        AmountText.text(entry.amount)
    }

    var predicate: String {
        "を\(verb)"
    }

    var message: String {
        "\(subject) \(amountText) \(predicate)"
    }

    static func label(
        for entry: Entry,
        category: (EntryCategory.ID) -> EntryCategory?,
        wallet: (Wallet.ID) -> Wallet?
    ) -> String {
        guard entry.type == .transfer else {
            return entry.categoryId.flatMap(category)?.name ?? ""
        }

        let from = wallet(entry.walletId)?.name ?? ""
        let to = entry.toWalletId.flatMap(wallet)?.name ?? ""

        return "\(from) → \(to)"
    }
}

private extension EntryChange {
    var verb: String {
        switch kind {
        case .recorded: entry.type == .transfer ? "振り替えました" : "記録しました"
        case .edited: "変えました"
        case .deleted: "消しました"
        }
    }
}

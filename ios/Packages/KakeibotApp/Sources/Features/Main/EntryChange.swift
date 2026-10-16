import Core
import DesignSystem

public struct EntryChange: Hashable, Sendable {
    public let kind: Kind
    public let entry: Entry
    public let label: String

    public init(
        kind: Kind,
        entry: Entry,
        label: String
    ) {
        self.kind = kind
        self.entry = entry
        self.label = label
    }
}

public extension EntryChange {
    enum Kind: Hashable, Sendable {
        case recorded
        case edited(previous: Entry)
        case deleted
    }

    var message: String {
        "\(label) \(AmountText.text(entry.amount)) を\(verb)"
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
        case .edited: "変更しました"
        case .deleted: "削除しました"
        }
    }
}

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
}

private extension EntryChange {
    var verb: String {
        switch kind {
        case .recorded: entry.type == .transfer ? "振り替えた" : "記録した"
        case .edited: "直した"
        case .deleted: "消した"
        }
    }
}

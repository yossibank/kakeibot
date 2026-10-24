import Core

public struct EntryBatch: Hashable, Sendable {
    public let kind: Kind
    public let previous: [Entry]

    public init(
        kind: Kind,
        previous: [Entry]
    ) {
        self.kind = kind
        self.previous = previous
    }
}

public extension EntryBatch {
    enum Kind: Hashable, Sendable {
        case changedCategory
        case changedWallet
        case deleted
    }

    var message: String {
        let count = "\(previous.count) 件"

        switch kind {
        case .changedCategory: return "\(count)のカテゴリを変えました"
        case .changedWallet: return "\(count)の口座を変えました"
        case .deleted: return "\(count)を削除しました"
        }
    }
}

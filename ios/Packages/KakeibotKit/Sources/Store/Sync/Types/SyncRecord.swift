public struct SyncRecord: Hashable, Sendable {
    public let key: SyncKey
    public let values: [String: SyncValue]

    public init(
        key: SyncKey,
        values: [String: SyncValue]
    ) {
        self.key = key
        self.values = values
    }
}

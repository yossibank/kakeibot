public struct SyncRecordID: Hashable, Sendable {
    public let key: SyncKey
    public let zoneName: String

    public init(
        key: SyncKey,
        zoneName: String
    ) {
        self.key = key
        self.zoneName = zoneName
    }
}

public struct SyncKey: Hashable, Sendable {
    public let table: SyncTable
    public let id: String

    public init(
        table: SyncTable,
        id: String
    ) {
        self.table = table
        self.id = id
    }
}

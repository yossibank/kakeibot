public struct SyncChange: Hashable, Sendable {
    public let key: SyncKey
    public let isDeletion: Bool
    public let saveZone: String?
    public let deleteZones: [String]

    let version: Int64
}

public extension SyncChange {
    var zones: [String] {
        (saveZone.map { [$0] } ?? []) + deleteZones
    }
}

import Foundation

public struct SyncSummary: Hashable, Sendable {
    public let entryCount: Int
    public let updatedAt: Date?

    public init(
        entryCount: Int,
        updatedAt: Date?
    ) {
        self.entryCount = entryCount
        self.updatedAt = updatedAt
    }
}

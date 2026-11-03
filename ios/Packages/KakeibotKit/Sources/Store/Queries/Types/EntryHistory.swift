import Foundation

public struct EntryHistory: Equatable, Sendable {
    public let count: Int
    public let firstCreatedAt: Date?

    public init(
        count: Int,
        firstCreatedAt: Date?
    ) {
        self.count = count
        self.firstCreatedAt = firstCreatedAt
    }
}

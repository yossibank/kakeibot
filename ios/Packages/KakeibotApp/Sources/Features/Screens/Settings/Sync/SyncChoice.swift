import Foundation
import Store

public struct SyncChoice: Hashable, Sendable {
    public let local: SyncSummary
    public let cloud: SyncSummary

    public init(
        local: SyncSummary,
        cloud: SyncSummary
    ) {
        self.local = local
        self.cloud = cloud
    }
}

public extension SyncChoice {
    enum Side: Sendable {
        case local
        case cloud
    }

    var newer: Side? {
        let localMinute = local.updatedAt.map(Self.minute)
        let cloudMinute = cloud.updatedAt.map(Self.minute)

        switch (localMinute, cloudMinute) {
        case let (local?, cloud?) where local > cloud:
            return .local
        case let (local?, cloud?) where local < cloud:
            return .cloud
        case (_?, nil):
            return .local
        case (nil, _?):
            return .cloud
        default:
            return nil
        }
    }
}

private extension SyncChoice {
    static func minute(_ date: Date) -> Int {
        Int((date.timeIntervalSinceReferenceDate / 60).rounded(.down))
    }
}

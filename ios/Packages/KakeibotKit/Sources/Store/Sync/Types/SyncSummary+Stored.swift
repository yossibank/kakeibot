import Core
import Foundation

public extension SyncSummary {
    init(
        entryCount: Int,
        latestUpdate: String?
    ) {
        self.init(
            entryCount: entryCount,
            updatedAt: latestUpdate.flatMap(Date.stored)
        )
    }
}

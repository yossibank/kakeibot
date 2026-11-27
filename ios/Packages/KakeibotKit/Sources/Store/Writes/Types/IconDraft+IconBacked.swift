import Core
import Foundation

extension IconDraft: IconBackedDraft {
    func newRecord(
        iconId: Icon.ID,
        sortOrder: Int,
        at now: Date
    ) throws -> ShelfIcon {
        ShelfIcon(iconId: iconId, sortOrder: sortOrder, createdAt: now, updatedAt: now)
    }

    func applied(
        to record: ShelfIcon,
        at now: Date
    ) throws -> ShelfIcon {
        var updated = record
        updated.updatedAt = now
        return updated
    }
}

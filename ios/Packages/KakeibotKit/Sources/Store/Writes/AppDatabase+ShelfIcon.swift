import Core
import Foundation
import GRDB

public extension AppDatabase {
    enum ShelfIconWriteError: Error, Equatable {
        case shelfIconNotFound
        case iconNotFound
    }

    @discardableResult
    func saveShelfIcon(
        _ draft: IconDraft,
        editing id: ShelfIcon.ID? = nil,
        at now: Date
    ) async throws -> ShelfIcon {
        try await writer.write { db in
            if let id {
                try Self.updateShelfIcon(id, with: draft, in: db, at: now)
            } else {
                try Self.insertShelfIcon(draft, into: db, at: now)
            }
        }
    }

    func reorderShelfIcons(
        _ ids: [ShelfIcon.ID],
        at now: Date
    ) async throws {
        try await writer.write { db in
            try ShelfIcon.reorder(
                ids,
                orThrow: ShelfIconWriteError.shelfIconNotFound,
                in: db,
                at: now
            )
        }
    }

    func setShelfIconHidden(
        _ id: ShelfIcon.ID,
        isHidden: Bool,
        at now: Date
    ) async throws {
        try await writer.write { db in
            guard var shelfIcon = try ShelfIcon.fetchOne(db, key: id) else {
                throw ShelfIconWriteError.shelfIconNotFound
            }

            shelfIcon.archivedAt = isHidden ? now : nil
            shelfIcon.updatedAt = now
            try shelfIcon.update(db)
        }
    }
}

private extension AppDatabase {
    static func insertShelfIcon(
        _ draft: IconDraft,
        into db: Database,
        at now: Date
    ) throws -> ShelfIcon {
        let icon = try draft.newIcon(at: now)

        let shelfIcon = try ShelfIcon(
            iconId: icon.id,
            sortOrder: ShelfIcon.nextSortOrder(in: db),
            createdAt: now,
            updatedAt: now
        )

        try icon.insert(db)
        try shelfIcon.insert(db)
        return shelfIcon
    }

    static func updateShelfIcon(
        _ id: ShelfIcon.ID,
        with draft: IconDraft,
        in db: Database,
        at now: Date
    ) throws -> ShelfIcon {
        guard var shelfIcon = try ShelfIcon.fetchOne(db, key: id) else {
            throw ShelfIconWriteError.shelfIconNotFound
        }

        guard let icon = try Icon.fetchOne(db, key: shelfIcon.iconId) else {
            throw ShelfIconWriteError.iconNotFound
        }

        try draft.applied(to: icon, at: now).update(db)
        shelfIcon.updatedAt = now
        try shelfIcon.update(db)
        return shelfIcon
    }
}

import Core
import Foundation
import GRDB

public extension AppDatabase {
    @discardableResult
    func save(
        _ draft: WalletDraft,
        editing id: Wallet.ID? = nil,
        at now: Date
    ) async throws -> Wallet {
        try await saveIconBacked(draft, editing: id, at: now)
    }

    @discardableResult
    func save(
        _ draft: EntryCategoryDraft,
        editing id: EntryCategory.ID? = nil,
        at now: Date
    ) async throws -> EntryCategory {
        try await saveIconBacked(draft, editing: id, at: now)
    }

    @discardableResult
    func save(
        _ draft: RewardRuleDraft,
        editing id: RewardRule.ID? = nil,
        at now: Date
    ) async throws -> RewardRule {
        try await saveIconBacked(draft, editing: id, at: now)
    }

    @discardableResult
    func save(
        _ draft: IconDraft,
        editing id: ShelfIcon.ID? = nil,
        at now: Date
    ) async throws -> ShelfIcon {
        try await saveIconBacked(draft, editing: id, at: now)
    }
}

extension AppDatabase {
    static func insertIconBacked<Draft: IconBackedDraft>(
        _ draft: Draft,
        into db: Database,
        at now: Date
    ) throws -> Draft.Record {
        let icon = try draft.newIcon(at: now)
        let sortOrder = try draft.sortOrder(in: db)
        let record = try draft.newRecord(iconId: icon.id, sortOrder: sortOrder, at: now)

        try icon.insert(db)
        try record.insert(db)

        return record
    }

    static func updateIconBacked<Draft: IconBackedDraft>(
        _ id: Draft.Record.ID,
        with draft: Draft,
        in db: Database,
        at now: Date
    ) throws -> Draft.Record {
        guard let existing = try Draft.Record.fetchOne(db, key: id) else {
            throw Draft.Record.notFound
        }

        guard let icon = try Icon.fetchOne(db, key: existing.iconId) else {
            throw Draft.Record.iconNotFound
        }

        let record = try draft.locked(by: existing, in: db).applied(to: existing, at: now)

        try draft.applied(to: icon, at: now).update(db)
        try record.update(db)

        return record
    }

    func saveIconBacked<Draft: IconBackedDraft>(
        _ draft: Draft,
        editing id: Draft.Record.ID?,
        at now: Date
    ) async throws -> Draft.Record {
        try await writer.write { db in
            if let id {
                try Self.updateIconBacked(id, with: draft, in: db, at: now)
            } else {
                try Self.insertIconBacked(draft, into: db, at: now)
            }
        }
    }
}

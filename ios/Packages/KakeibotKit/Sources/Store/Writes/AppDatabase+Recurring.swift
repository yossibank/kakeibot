import Core
import Foundation
import GRDB

public extension AppDatabase {
    enum RecurringWriteError: Error, Equatable {
        case recurringNotFound
    }

    @discardableResult
    func saveRecurring(
        _ draft: RecurringDraft,
        editing id: Recurring.ID? = nil,
        today: LocalDate,
        at now: Date
    ) async throws -> Recurring {
        try await writer.write { db in
            var recurring: Recurring

            if let id {
                guard let current = try Recurring.fetchOne(db, key: id) else {
                    throw RecurringWriteError.recurringNotFound
                }

                recurring = try draft.applied(to: current, at: now)
                try recurring.update(db)
            } else {
                recurring = try draft.newRecurring(at: now)
                recurring.sortOrder = try Recurring.nextSortOrder(in: db)
                try recurring.insert(db)
            }

            try Self.generateEntries(
                of: recurring,
                through: today,
                in: db,
                at: now
            )

            return try Recurring.fetchOne(db, key: recurring.id) ?? recurring
        }
    }

    func setRecurringHidden(
        _ id: Recurring.ID,
        isHidden: Bool,
        today: LocalDate,
        at now: Date
    ) async throws {
        try await writer.write { db in
            guard var recurring = try Recurring.fetchOne(db, key: id) else {
                throw RecurringWriteError.recurringNotFound
            }

            recurring.archivedAt = isHidden ? now : nil
            recurring.updatedAt = now

            if !isHidden {
                let yesterday = today.adding(days: -1)
                let generated = recurring.generatedUntil ?? yesterday
                recurring.generatedUntil = max(generated, yesterday)
            }

            try recurring.update(db)

            try Self.generateEntries(
                of: recurring,
                through: today,
                in: db,
                at: now
            )
        }
    }

    func deleteRecurring(_ id: Recurring.ID) async throws {
        try await writer.write { db in
            try Entry
                .filter(Column("recurring_id") == id)
                .updateAll(
                    db,
                    Column("recurring_id").set(to: nil),
                    Column("recurring_date").set(to: nil)
                )

            _ = try Recurring.deleteOne(db, key: id)
        }
    }

    func reorderRecurrings(
        _ ids: [Recurring.ID],
        at now: Date
    ) async throws {
        try await writer.write { db in
            try Recurring.reorder(
                ids,
                orThrow: RecurringWriteError.recurringNotFound,
                in: db,
                at: now
            )
        }
    }

    func generateRecurringEntries(
        through today: LocalDate,
        at now: Date
    ) async throws {
        try await writer.write { db in
            for recurring in try Recurring.fetchAll(db) {
                try Self.generateEntries(
                    of: recurring,
                    through: today,
                    in: db,
                    at: now
                )
            }
        }
    }
}

private extension AppDatabase {
    static let sameDateMargin = 10

    static func generateEntries(
        of recurring: Recurring,
        through today: LocalDate,
        in db: Database,
        at now: Date
    ) throws {
        let dates = recurring.archivedAt == nil
            ? recurring.pendingDates(through: today)
            : []

        for date in dates {
            let earliest = date.adding(days: -sameDateMargin)
            let latest = date.adding(days: sameDateMargin)
            let exists = try Entry
                .filter(Column("recurring_id") == recurring.id)
                .filter(Column("recurring_date") >= earliest)
                .filter(Column("recurring_date") <= latest)
                .fetchCount(db) > 0

            guard !exists else {
                continue
            }

            let entry = Entry(
                type: recurring.type,
                amount: recurring.amount,
                date: date,
                categoryId: recurring.categoryId,
                walletId: recurring.walletId,
                toWalletId: recurring.toWalletId,
                memo: recurring.memo,
                recurringId: recurring.id,
                recurringDate: date,
                createdAt: now,
                updatedAt: now
            )

            try entry.insert(db)

            if entry.type == .expense {
                try NoSpendDay.deleteOne(db, key: date)
            }
        }

        guard recurring.startDate <= today else {
            return
        }

        var updated = recurring
        updated.generatedUntil = today
        try updated.update(db)
    }
}

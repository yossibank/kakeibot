import Core
import Foundation
import GRDB

public extension AppDatabase {
    enum RewardRuleWriteError: Error, Equatable {
        case ruleNotFound
        case iconNotFound
    }

    @discardableResult
    func saveRewardRule(
        _ draft: RewardRuleDraft,
        editing id: RewardRule.ID? = nil,
        at now: Date
    ) async throws -> RewardRule {
        try await writer.write { db in
            if let id {
                try Self.updateRewardRule(id, with: draft, in: db, at: now)
            } else {
                try Self.insertRewardRule(draft, into: db, at: now)
            }
        }
    }

    func reorderRewardRules(
        _ ids: [RewardRule.ID],
        at now: Date
    ) async throws {
        try await writer.write { db in
            try RewardRule.reorder(
                ids,
                orThrow: RewardRuleWriteError.ruleNotFound,
                in: db,
                at: now
            )
        }
    }

    func setRewardRuleHidden(
        _ id: RewardRule.ID,
        isHidden: Bool,
        at now: Date
    ) async throws {
        try await writer.write { db in
            guard var rule = try RewardRule.fetchOne(db, key: id) else {
                throw RewardRuleWriteError.ruleNotFound
            }

            rule.isActive = !isHidden
            rule.updatedAt = now

            try rule.update(db)
        }
    }

    @discardableResult
    func deleteRewardRule(_ id: RewardRule.ID) async throws -> Deletion {
        try await writer.write { db in
            guard let rule = try RewardRule.fetchOne(db, key: id) else {
                throw RewardRuleWriteError.ruleNotFound
            }

            let logs = RewardLog.filter(Column("rule_id") == id)

            let deletion = try Deletion(
                rewardRules: [rule],
                rewardLogs: logs.fetchAll(db)
            )

            try logs.deleteAll(db)
            try rule.delete(db)

            return deletion
        }
    }
}

private extension AppDatabase {
    static func insertRewardRule(
        _ draft: RewardRuleDraft,
        into db: Database,
        at now: Date
    ) throws -> RewardRule {
        let icon = try draft.newIcon(at: now)

        let rule = try draft.newRule(
            iconId: icon.id,
            sortOrder: RewardRule.nextSortOrder(in: db),
            at: now
        )

        try icon.insert(db)
        try rule.insert(db)

        return rule
    }

    static func updateRewardRule(
        _ id: RewardRule.ID,
        with draft: RewardRuleDraft,
        in db: Database,
        at now: Date
    ) throws -> RewardRule {
        guard let rule = try RewardRule.fetchOne(db, key: id) else {
            throw RewardRuleWriteError.ruleNotFound
        }

        guard let icon = try Icon.fetchOne(db, key: rule.iconId) else {
            throw RewardRuleWriteError.iconNotFound
        }

        try draft.applied(to: icon, at: now).update(db)

        let updated = try draft.applied(to: rule, at: now)

        try updated.update(db)

        return updated
    }
}

import Core
import Foundation
import GRDB

public extension AppDatabase {
    enum RewardGoalWriteError: Error, Equatable {
        case goalNotFound
    }

    @discardableResult
    func saveRewardGoal(
        _ draft: RewardGoalDraft,
        editing id: RewardGoal.ID? = nil,
        at now: Date
    ) async throws -> RewardGoal {
        try await writer.write { db in
            guard let id else {
                let goal = try draft.newGoal(at: now)
                try goal.insert(db)
                return goal
            }

            guard let goal = try RewardGoal.fetchOne(db, key: id) else {
                throw RewardGoalWriteError.goalNotFound
            }

            let updated = try draft.applied(to: goal, at: now)
            try updated.update(db)
            return updated
        }
    }

    func setRewardGoalPurchased(
        _ id: RewardGoal.ID,
        isPurchased: Bool,
        at now: Date
    ) async throws {
        try await writer.write { db in
            guard var goal = try RewardGoal.fetchOne(db, key: id) else {
                throw RewardGoalWriteError.goalNotFound
            }

            goal.purchasedAt = isPurchased ? now : nil
            goal.updatedAt = now
            try goal.update(db)
        }
    }

    func deleteRewardGoal(_ id: RewardGoal.ID) async throws {
        try await writer.write { db in
            guard try RewardGoal.deleteOne(db, key: id) else {
                throw RewardGoalWriteError.goalNotFound
            }
        }
    }
}

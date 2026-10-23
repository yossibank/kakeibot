import Foundation

public struct RewardGoalDraft: Hashable, Sendable {
    public var name: String
    public var targetAmount: Int

    public init(
        name: String,
        targetAmount: Int
    ) {
        self.name = name
        self.targetAmount = targetAmount
    }
}

public extension RewardGoalDraft {
    var problems: [DraftProblem] {
        let nameProblems: [DraftProblem] = trimmedName.isEmpty
            ? [.emptyName]
            : []

        let amountProblems: [DraftProblem] = targetAmount > 0
            ? []
            : [.emptyAmount]

        return nameProblems + amountProblems
    }

    init(_ goal: RewardGoal) {
        self.init(name: goal.name, targetAmount: goal.targetAmount)
    }

    func newGoal(at now: Date) throws -> RewardGoal {
        try validate()

        return RewardGoal(
            name: trimmedName,
            targetAmount: targetAmount,
            createdAt: now,
            updatedAt: now
        )
    }

    func applied(
        to goal: RewardGoal,
        at now: Date
    ) throws -> RewardGoal {
        try validate()

        var updated = goal

        updated.name = trimmedName
        updated.targetAmount = targetAmount
        updated.updatedAt = now

        return updated
    }
}

private extension RewardGoalDraft {
    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func validate() throws {
        if let problem = problems.first {
            throw problem
        }
    }
}

import Foundation

public struct RewardRuleDraft: Hashable, Sendable {
    public var name: String
    public var amount: Int
    public var icon: IconDraft

    public init(
        name: String,
        amount: Int,
        icon: IconDraft
    ) {
        self.name = name
        self.amount = amount
        self.icon = icon
    }
}

public extension RewardRuleDraft {
    var problems: [DraftProblem] {
        let nameProblems: [DraftProblem] = trimmedName.isEmpty
            ? [.emptyName]
            : []

        let amountProblems: [DraftProblem] = amount > 0 ? [] : [.emptyAmount]
        return nameProblems + amountProblems + icon.problems
    }

    init(
        _ rule: RewardRule,
        icon: Icon
    ) {
        self.init(
            name: rule.name,
            amount: rule.amount,
            icon: IconDraft(icon)
        )
    }

    func newIcon(at now: Date) throws -> Icon {
        try validate()
        return try icon.newIcon(at: now)
    }

    func newRule(
        iconId: Icon.ID,
        sortOrder: Int,
        at now: Date
    ) throws -> RewardRule {
        try validate()

        return RewardRule(
            name: trimmedName,
            amount: amount,
            iconId: iconId,
            isActive: true,
            sortOrder: sortOrder,
            createdAt: now,
            updatedAt: now
        )
    }

    func applied(
        to icon: Icon,
        at now: Date
    ) throws -> Icon {
        try validate()
        return try self.icon.applied(to: icon, at: now)
    }

    func applied(
        to rule: RewardRule,
        at now: Date
    ) throws -> RewardRule {
        try validate()

        var updated = rule
        updated.name = trimmedName
        updated.amount = amount
        updated.updatedAt = now
        return updated
    }
}

private extension RewardRuleDraft {
    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func validate() throws {
        if let problem = problems.first {
            throw problem
        }
    }
}

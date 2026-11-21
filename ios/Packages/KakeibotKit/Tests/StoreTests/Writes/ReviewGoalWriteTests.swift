import Core
import Foundation
import Store
import Testing

struct ReviewGoalWriteTests {
    @Test
    func savesAndUpdatesGoal() async throws {
        let database = try AppDatabase.inMemory()
        var goal = Self.goal()

        try await database.saveReviewGoal(goal)
        let saved = try await database.reviewGoals(for: Self.period)

        goal.result = 6
        goal.saved = 2627
        goal.checkedAt = Self.now
        try await database.saveReviewGoal(goal)
        let checked = try await database.reviewGoals(for: Self.period)

        #expect(saved == [Self.goal(id: goal.id)])
        #expect(checked == [goal])
        #expect(checked.first?.isAchieved == true)
    }

    @Test
    func keepsGoalsOfEachPeriodApart() async throws {
        let database = try AppDatabase.inMemory()
        let first = Self.goal()
        let second = Self.goal(memo: "ライフ")
        let other = Self.goal(period: "month:2026-12-01")

        try await database.saveReviewGoal(first)
        try await database.saveReviewGoal(second)
        try await database.saveReviewGoal(other)
        let goals = try await database.reviewGoals(for: Self.period)

        #expect(Set(goals) == [first, second])
    }

    @Test
    func deletesGoalsWithRecords() async throws {
        let database = try AppDatabase.inMemory()

        try await database.saveReviewGoal(Self.goal())
        try await database.deleteAllRecords(at: Self.now)
        let goals = try await database.reviewGoals(for: Self.period)

        #expect(goals.isEmpty)
    }

    @Test
    func deletesGoalsOnRestore() async throws {
        let database = try AppDatabase.inMemory()

        try database.insertDefaultsIfEmpty(at: Self.now)
        let tables = try database.snapshot()
        try await database.saveReviewGoal(Self.goal())
        try database.replace(with: tables)
        let goals = try await database.reviewGoals(for: Self.period)

        #expect(goals.isEmpty)
    }
}

private extension ReviewGoalWriteTests {
    static let period = "month:2026-11-01"
    static let now = Date(timeIntervalSince1970: 1_794_000_000)

    static func goal(
        id: ReviewGoal.ID = ReviewGoal.ID(),
        period: String = period,
        memo: String? = nil
    ) -> ReviewGoal {
        ReviewGoal(
            id: id,
            period: period,
            kind: .count,
            categoryId: nil,
            memo: memo,
            baseline: 9,
            target: 7,
            saving: 5254,
            createdAt: now
        )
    }
}

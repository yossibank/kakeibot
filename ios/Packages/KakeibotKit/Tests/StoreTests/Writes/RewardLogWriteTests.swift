import Core
import Foundation
import GRDB
@testable import Store
import Testing

struct RewardLogWriteTests {
    @Test
    func achievesAndClearsReward() async throws {
        let setup = try await Setup()

        try await setup.achieve(true)
        try await setup.achieve(true)
        let achieved = try await setup.database.rewardBank()

        try await setup.achieve(false)
        let cleared = try await setup.database.rewardBank()

        #expect(achieved.logs.count == 1)
        #expect(achieved.total(on: setup.date) == 500)
        #expect(cleared.logs.isEmpty)
    }

    @Test
    func countsAchievementsPerRule() async throws {
        let setup = try await Setup()

        try await setup.achieve(true)
        let list = try await setup.database.rewardRuleList()
        let total = try #require(list.total(of: setup.rule))

        #expect(total.count == 1)
        #expect(total.amount == 500)
    }

    @Test
    func keepsAmountAtAchievement() async throws {
        let setup = try await Setup()
        try await setup.achieve(true)
        let draft = RewardRuleDraft(
            name: "自炊した日",
            amount: 800,
            icon: setup.icon
        )

        try await setup.database.saveRewardRule(
            draft,
            editing: setup.rule.id,
            at: setup.now
        )
        let bank = try await setup.database.rewardBank()

        #expect(bank.logs.map(\.amount) == [500])
    }

    @Test
    func subtractsBoughtGoals() async throws {
        let setup = try await Setup()
        try await setup.achieve(true)
        let bought = RewardGoal(
            name: "靴",
            targetAmount: 300,
            purchasedAt: setup.now,
            createdAt: setup.now,
            updatedAt: setup.now
        )
        let waiting = RewardGoal(
            name: "鞄",
            targetAmount: 1000,
            createdAt: setup.now,
            updatedAt: setup.now
        )
        try await setup.database.writer.write { db in
            try bought.insert(db)
            try waiting.insert(db)
        }

        let bank = try await setup.database.rewardBank()

        #expect(bank.balance == 200)
    }
}

private extension RewardLogWriteTests {
    struct Setup {
        let database: AppDatabase
        let rule: RewardRule
        let now = Date(timeIntervalSince1970: 0)
        let icon = IconDraft(mark: .glyph(.giftbox), color: "#E07A5F")
        let date: LocalDate

        init() async throws {
            let database = try AppDatabase.inMemory()
            let draft = RewardRuleDraft(
                name: "自炊した日",
                amount: 500,
                icon: icon
            )

            self.rule = try await database.saveRewardRule(draft, at: now)
            self.date = try #require(LocalDate("2026-10-22"))
            self.database = database
        }

        func achieve(_ isAchieved: Bool) async throws {
            try await database.setReward(
                rule.id,
                isAchieved: isAchieved,
                on: date,
                at: now
            )
        }
    }
}

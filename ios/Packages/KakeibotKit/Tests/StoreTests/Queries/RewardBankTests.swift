import Core
import Foundation
import Store
import Testing

struct RewardBankTests {
    @Test
    func listsHiddenRulesOnlyOnDaysTheyWereAchieved() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 0)
        let icon = IconDraft(mark: .glyph(.giftbox), color: "#E07A5F")
        let day = try #require(LocalDate("2026-10-22"))
        let other = try #require(LocalDate("2026-10-23"))

        let shown = try await database.saveRewardRule(
            RewardRuleDraft(name: "自炊した日", amount: 500, icon: icon),
            at: now
        )

        let hidden = try await database.saveRewardRule(
            RewardRuleDraft(name: "歩いて帰った日", amount: 300, icon: icon),
            at: now
        )

        try await database.setReward(hidden.id, isAchieved: true, on: day, at: now)
        try await database.setRewardRuleHidden(hidden.id, isHidden: true, at: now)
        let bank = try await database.rewardBank()

        #expect(bank.rules(on: day).map(\.id) == [shown.id, hidden.id])
        #expect(bank.rules(on: other).map(\.id) == [shown.id])
    }
}

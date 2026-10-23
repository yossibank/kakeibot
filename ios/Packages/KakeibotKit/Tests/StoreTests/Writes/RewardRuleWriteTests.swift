import Core
import Foundation
import GRDB
@testable import Store
import Testing

struct RewardRuleWriteTests {
    @Test
    func addsRulesInOrder() async throws {
        let setup = try Setup()

        let first = try await setup.save("自炊した日")
        let second = try await setup.save("歩いて帰った日")
        let list = try await setup.database.rewardRuleList()
        let icon = try #require(list.icons[first.iconId])

        #expect(list.rules == [first, second])
        #expect(first.sortOrder == 0)
        #expect(second.sortOrder == 1)
        #expect(first.isActive)
        #expect(icon.glyph == .giftbox)
    }

    @Test
    func updatesRuleAndIcon() async throws {
        let setup = try Setup()
        let rule = try await setup.save("自炊した日")
        let later = setup.now.addingTimeInterval(60)

        let draft = RewardRuleDraft(
            name: " お弁当の日 ",
            amount: 300,
            icon: IconDraft(mark: .text("弁"), color: "#9C6ADE")
        )

        let updated = try await setup.database.saveRewardRule(
            draft,
            editing: rule.id,
            at: later
        )

        let list = try await setup.database.rewardRuleList()
        let icon = try #require(list.icons[updated.iconId])

        #expect(updated.id == rule.id)
        #expect(updated.name == "お弁当の日")
        #expect(updated.amount == 300)
        #expect(updated.updatedAt == later)
        #expect(icon.text == "弁")
    }

    @Test
    func rejectsRuleWithoutAmount() async throws {
        let setup = try Setup()

        let draft = RewardRuleDraft(
            name: "自炊した日",
            amount: 0,
            icon: setup.icon
        )

        await #expect(throws: DraftProblem.emptyAmount) {
            try await setup.database.saveRewardRule(draft, at: setup.now)
        }
    }

    @Test
    func reordersRules() async throws {
        let setup = try Setup()
        let first = try await setup.save("自炊した日")
        let second = try await setup.save("歩いて帰った日")

        try await setup.database.reorderRewardRules(
            [second.id, first.id],
            at: setup.now
        )
        let list = try await setup.database.rewardRuleList()

        #expect(list.rules.map(\.id) == [second.id, first.id])
    }

    @Test
    func hidesAndShowsRule() async throws {
        let setup = try Setup()
        let rule = try await setup.save("自炊した日")

        try await setup.database.setRewardRuleHidden(
            rule.id,
            isHidden: true,
            at: setup.now
        )
        let hidden = try await setup.database.rewardRuleList()

        try await setup.database.setRewardRuleHidden(
            rule.id,
            isHidden: false,
            at: setup.now
        )
        let shown = try await setup.database.rewardRuleList()

        #expect(hidden.rules.first?.isActive == false)
        #expect(shown.rules.first?.isActive == true)
    }

    @Test
    func deletesRuleWithLogsAndRestores() async throws {
        let setup = try Setup()
        let rule = try await setup.save("自炊した日")
        let date = try #require(LocalDate("2026-10-22"))

        let log = RewardLog(
            ruleId: rule.id,
            date: date,
            amount: rule.amount,
            createdAt: setup.now
        )

        try await setup.database.writer.write { db in
            try log.insert(db)
        }

        let deletion = try await setup.database.deleteRewardRule(rule.id)
        let deleted = try await setup.database.rewardRuleList()
        let deletedLogs = try await setup.logs()

        try await setup.database.restore(deletion)
        let restored = try await setup.database.rewardRuleList()
        let restoredLogs = try await setup.logs()

        #expect(deleted.rules.isEmpty)
        #expect(deletedLogs.isEmpty)
        #expect(restored.rules == [rule])
        #expect(restoredLogs == [log])
    }
}

private extension RewardRuleWriteTests {
    struct Setup {
        let database: AppDatabase
        let now = Date(timeIntervalSince1970: 0)
        let icon = IconDraft(mark: .glyph(.giftbox), color: "#E07A5F")

        init() throws {
            self.database = try AppDatabase.inMemory()
        }

        func save(_ name: String) async throws -> RewardRule {
            let draft = RewardRuleDraft(name: name, amount: 500, icon: icon)
            return try await database.saveRewardRule(draft, at: now)
        }

        func logs() async throws -> [RewardLog] {
            try await database.writer.read { db in
                try RewardLog.fetchAll(db)
            }
        }
    }
}

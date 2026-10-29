import Core
import Features
import Foundation
import Store
import Testing

extension AssetsModelTests {
    @Test
    func groupsRewardHistoryAcrossMonths() async throws {
        let setup = try await Setup()
        let rule = try await setup.saveRule(amount: 500)
        try await setup.achieve(rule, on: "2026-09-30")
        try await setup.achieve(rule, on: "2026-10-01")
        try await setup.achieve(rule, on: "2026-10-02")

        let model = try await setup.runningModel()
        let history = model.rewardHistory

        #expect(history.map(\.month) == [
            YearMonth(year: 2026, month: 10),
            YearMonth(year: 2026, month: 9)
        ])
        #expect(history.map(\.logs.count) == [2, 1])
        #expect(model.rewardBalance == 1500)
        #expect(model.recentRewards.count == 3)
    }

    @Test
    func reachesGoalAtZeroRemaining() async throws {
        let setup = try await Setup()
        let rule = try await setup.saveRule(amount: 1000)
        try await setup.achieve(rule, on: "2026-10-01")
        try await setup.saveGoal(target: 1000)

        let model = try await setup.runningModel()
        let goal = try #require(model.rewardGoal)

        #expect(model.remaining(to: goal) == 0)
        #expect(model.percent(to: goal) == 100)
        #expect(model.isRewardGoalReached)
    }

    @Test
    func tellsWhenPurchaseCannotBeSaved() async throws {
        let setup = try await Setup()
        let rule = try await setup.saveRule(amount: 1000)
        try await setup.achieve(rule, on: "2026-10-01")
        let goal = try await setup.saveGoal(target: 1000)
        let model = AssetsModel(database: setup.database, today: setup.today)
        try await setup.database.failWrites(to: "reward_goal")

        let isSaved = await model.setPurchased(goal.id, isPurchased: true)

        #expect(isSaved == false)
        #expect(model.errorNotice.message == "目標を保存できませんでした")
    }

    @Test
    func refusesPurchaseShortOfBalance() async throws {
        let setup = try await Setup()
        let goal = try await setup.saveGoal(target: 1000)
        let model = AssetsModel(database: setup.database, today: setup.today)

        let isSaved = await model.setPurchased(goal.id, isPurchased: true)

        #expect(isSaved == false)
        #expect(model.errorNotice.message == "目標を保存できませんでした")
    }

    @Test
    func countsLoanRepaidFromZeroToOverpaid() async throws {
        let setup = try await Setup()
        let fresh = try await setup.saveLoan("奨学金", balance: -100_000)
        let overpaid = try await setup.saveLoan("車", balance: -50000)
        try await setup.save(.transfer, 60000, on: "2026-10-10", from: setup.bank, to: overpaid)

        let model = AssetsModel(database: setup.database, today: setup.today)
        await model.load()
        let freshRow = try #require(model.rows.first { $0.wallet.id == fresh })
        let overpaidRow = try #require(model.rows.first { $0.wallet.id == overpaid })
        let cashRow = try #require(model.rows.first { $0.wallet.id == setup.cash })

        #expect(freshRow.repaidPercent == 0)
        #expect(overpaidRow.balance == 10000)
        #expect(overpaidRow.repaidPercent == 100)
        #expect(cashRow.repaidPercent == nil)
    }
}

extension AssetsModelTests.Setup {
    func saveRule(amount: Int) async throws -> RewardRule {
        let icon = IconDraft(mark: .glyph(.giftbox), color: "#E07A5F")
        let draft = RewardRuleDraft(name: "自炊した日", amount: amount, icon: icon)

        return try await database.saveRewardRule(draft, at: Date())
    }

    func achieve(
        _ rule: RewardRule,
        on text: String
    ) async throws {
        let date = try #require(LocalDate(text))
        try await database.setReward(rule.id, isAchieved: true, on: date, at: Date())
    }

    @discardableResult
    func saveGoal(target: Int) async throws -> RewardGoal {
        let draft = RewardGoalDraft(name: "新しい靴", targetAmount: target)
        return try await database.saveRewardGoal(draft, at: Date())
    }

    func saveLoan(
        _ name: String,
        balance: Int
    ) async throws -> Wallet.ID {
        let draft = WalletDraft(
            kind: .loan,
            name: name,
            mark: .glyph(.contract),
            color: "#4A6FA5",
            initialBalance: balance,
            loanAmount: -balance
        )

        return try await database.saveWallet(draft, at: Date()).id
    }

    @MainActor
    func runningModel() async throws -> AssetsModel {
        let model = AssetsModel(database: database, today: today)

        let task = Task {
            await model.run()
        }

        await ObservationWait.until {
            model.rewardBank != nil && model.list != nil
        }

        task.cancel()

        return model
    }
}

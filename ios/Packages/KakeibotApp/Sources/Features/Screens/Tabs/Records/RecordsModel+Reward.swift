import Core
import DesignSystem
import Foundation
import Store

public extension RecordsModel {
    var rewardRules: [RewardRule] {
        rewardBank?.activeRules ?? []
    }

    func rewardRules(on date: LocalDate) -> [RewardRule] {
        rewardBank?.rules(on: date) ?? []
    }

    func rewardIcon(for rule: RewardRule) -> Icon? {
        rewardBank?.icon(for: rule)
    }

    func rewardTotal(on date: LocalDate) -> Int {
        rewardBank?.total(on: date) ?? 0
    }

    func isAchieved(
        _ rule: RewardRule,
        on date: LocalDate
    ) -> Bool {
        let logs = rewardBank?.logs(on: date) ?? []
        return logs.contains { $0.ruleId == rule.id }
    }

    func rewardRuleEditModel() -> RewardRuleEditModel {
        RewardRuleEditModel(database: database)
    }

    func toggleReward(
        _ rule: RewardRule,
        on date: LocalDate
    ) async {
        guard canReward(on: date) else {
            return
        }

        let isAchieved = !isAchieved(rule, on: date)

        guard rule.isActive || !isAchieved else {
            return
        }

        do {
            try await database.setReward(
                rule.id,
                isAchieved: isAchieved,
                on: date,
                at: Date()
            )
        } catch AppDatabase.RewardRuleWriteError.shortOfBalance {
            errorNotice.show(Self.rewardShortOfBalanceMessage)
        } catch {
            errorNotice.show(Self.saveFailedMessage)
        }
    }

    func canReward(on date: LocalDate) -> Bool {
        date <= today
    }
}

private extension RecordsModel {
    static let rewardShortOfBalanceMessage = "貯金箱の残高が足りないため、達成を外せません"
}

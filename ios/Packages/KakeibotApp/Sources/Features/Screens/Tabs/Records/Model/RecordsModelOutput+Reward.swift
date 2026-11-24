import Core
import DesignSystem
import Store

public extension RecordsModel.Output {
    var rewardRules: [RewardRule] {
        input.rewardBank?.activeRules ?? []
    }

    func rewardRules(on date: LocalDate) -> [RewardRule] {
        input.rewardBank?.rules(on: date) ?? []
    }

    func rewardIcon(for rule: RewardRule) -> Icon? {
        input.rewardBank?.icon(for: rule)
    }

    func rewardTotal(on date: LocalDate) -> Int {
        input.rewardBank?.total(on: date) ?? 0
    }

    func isAchieved(
        _ rule: RewardRule,
        on date: LocalDate
    ) -> Bool {
        let logs = input.rewardBank?.logs(on: date) ?? []
        return logs.contains { $0.ruleId == rule.id }
    }

    func canReward(on date: LocalDate) -> Bool {
        date <= state.today
    }
}

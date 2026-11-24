import Core
import DesignSystem
import Foundation
import Store

public extension RecordsModel {
    func rewardRuleEditModel() -> RewardRuleEditModel {
        RewardRuleEditModel(database: dependencies.database, clock: dependencies.clock)
    }

    func toggleReward(
        _ rule: RewardRule,
        on date: LocalDate
    ) async {
        guard output.canReward(on: date) else {
            return
        }

        let isAchieved = !output.isAchieved(rule, on: date)

        guard rule.isActive || !isAchieved else {
            return
        }

        do {
            try await dependencies.database.setReward(
                rule.id,
                isAchieved: isAchieved,
                on: date,
                at: dependencies.clock.now
            )
        } catch AppDatabase.RewardRuleWriteError.shortOfBalance {
            state.errorNotice.show(Self.rewardShortOfBalanceMessage)
        } catch {
            state.errorNotice.show(Self.saveFailedMessage, for: error)
        }
    }
}

private extension RecordsModel {
    static let rewardShortOfBalanceMessage = "貯金箱の残高が足りないため、達成を外せません"
}

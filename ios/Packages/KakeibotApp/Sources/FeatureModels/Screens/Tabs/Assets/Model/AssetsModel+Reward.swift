import Core
import Foundation
import Store

public extension AssetsModel {
    struct RewardMonth: Equatable {
        public let month: YearMonth
        public let logs: [RewardLog]
    }
}

public extension AssetsModel {
    func goalEditModel(editing goal: RewardGoal?) -> AssetsRewardGoalEditModel {
        AssetsRewardGoalEditModel(
            parts: dependencies,
            editing: goal,
            balance: input.rewardBank?.balance ?? 0
        )
    }

    @discardableResult
    func setPurchased(
        _ id: RewardGoal.ID,
        isPurchased: Bool
    ) async -> Bool {
        do {
            try await dependencies.database.setRewardGoalPurchased(
                id,
                isPurchased: isPurchased,
                at: dependencies.clock.now
            )

            if isPurchased {
                state.boughtId = id
            }

            return true
        } catch {
            state.errorNotice.show(Self.goalFailedMessage, for: error)
            return false
        }
    }

    func childParts() -> ScreenParts {
        dependencies
    }
}

private extension AssetsModel {
    static let goalFailedMessage = "目標を保存できませんでした"
}

extension AssetsModel.RewardMonth: Identifiable {
    public var id: YearMonth {
        month
    }
}

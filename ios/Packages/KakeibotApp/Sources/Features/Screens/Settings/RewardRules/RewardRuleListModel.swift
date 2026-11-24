import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class RewardRuleListModel {
    public let state: SettingsBoardMovingState<RewardRule.ID>
    public let input: SettingsBoardSnapshotInput<RewardRuleList>
    public let output: Output

    let dependencies: SettingsBoardDependencies

    public init(
        database: AppDatabase,
        clock: ScreenClock
    ) {
        let state = SettingsBoardMovingState<RewardRule.ID>()
        let input = SettingsBoardSnapshotInput<RewardRuleList>()

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = SettingsBoardDependencies(database: database, clock: clock)
    }
}

public extension RewardRuleListModel {
    @MainActor
    final class Output: SettingsBoardOutput {
        let input: SettingsBoardSnapshotInput<RewardRuleList>
        let state: SettingsBoardMovingState<RewardRule.ID>

        var items: [RewardRule] {
            input.snapshot?.rules ?? []
        }

        init(
            input: SettingsBoardSnapshotInput<RewardRuleList>,
            state: SettingsBoardMovingState<RewardRule.ID>
        ) {
            self.input = input
            self.state = state
        }

        public func icon(for rule: RewardRule) -> Icon? {
            input.snapshot?.icons[rule.iconId]
        }

        public func total(for rule: RewardRule) -> RewardRuleList.Total? {
            input.snapshot?.total(of: rule)
        }

        func isHidden(_ item: RewardRule) -> Bool {
            !item.isActive
        }
    }
}

extension RewardRuleListModel: SettingsBoardDatabaseModel {
    typealias Item = RewardRule

    static let loadFailedMessage = "決まりを読めませんでした"

    func read() async throws -> RewardRuleList {
        try await dependencies.database.rewardRuleList()
    }

    func updates() -> some AsyncSequence<RewardRuleList, any Error> {
        dependencies.database.rewardRuleListUpdates()
    }
}

extension RewardRuleListModel: SettingsBoardModel {
    public func isInUse(_ error: any Error) -> Bool {
        error as? AppDatabase.RewardRuleWriteError == .hasLogs
    }

    public func remove(_ id: RewardRule.ID) async throws -> Deletion {
        try await dependencies.database.deleteRewardRule(id)
    }
}

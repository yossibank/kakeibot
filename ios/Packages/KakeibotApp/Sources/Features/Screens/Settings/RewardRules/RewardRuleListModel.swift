import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class RewardRuleListModel {
    public var movingOrder: [RewardRule.ID]?
    public var errorNotice = ErrorNotice()

    public internal(set) var snapshot: RewardRuleList?

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension RewardRuleListModel {
    func icon(for rule: RewardRule) -> Icon? {
        snapshot?.icons[rule.iconId]
    }

    func total(for rule: RewardRule) -> RewardRuleList.Total? {
        snapshot?.total(of: rule)
    }
}

extension RewardRuleListModel: SettingsBoardDatabaseModel {
    typealias Item = RewardRule

    static let loadFailedMessage = "決まりを読めませんでした"

    func read() async throws -> RewardRuleList {
        try await database.rewardRuleList()
    }

    func updates() -> some AsyncSequence<RewardRuleList, any Error> {
        database.rewardRuleListUpdates()
    }

    func items(in snapshot: RewardRuleList) -> [RewardRule] {
        snapshot.rules
    }

    func isHidden(_ item: RewardRule) -> Bool {
        !item.isActive
    }
}

extension RewardRuleListModel: SettingsBoardModel {
    public func saveOrder(_ ids: [RewardRule.ID]) async throws {
        let ids = ids + hidden.map(\.id)
        try await database.reorder(ids, at: Date())
    }

    public func saveHidden(
        _ id: RewardRule.ID,
        isHidden: Bool
    ) async throws {
        try await database.setHidden(
            id,
            isHidden: isHidden,
            at: Date()
        )
    }

    public func isInUse(_ error: any Error) -> Bool {
        error as? AppDatabase.RewardRuleWriteError == .hasLogs
    }

    public func remove(_ id: RewardRule.ID) async throws -> Deletion {
        try await database.deleteRewardRule(id)
    }

    public func restoreRemoved(_ deletion: Deletion) async throws {
        try await database.restore(deletion)
    }
}

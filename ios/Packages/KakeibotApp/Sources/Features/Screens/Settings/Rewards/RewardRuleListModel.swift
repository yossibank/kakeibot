import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class RewardRuleListModel: ScreenModel {
    public private(set) var list: RewardRuleList?
    public var movingOrder: [RewardRule.ID]?

    public var errorNotice = ErrorNotice()

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension RewardRuleListModel {
    var visible: [RewardRule] {
        rules(isHidden: false)
    }

    var hidden: [RewardRule] {
        rules(isHidden: true)
    }

    func icon(for rule: RewardRule) -> Icon? {
        list?.icons[rule.iconId]
    }

    func load() async {
        do {
            list = try await database.rewardRuleList()
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func observe() async {
        await observe(
            database.rewardRuleListUpdates(),
            failure: Self.loadFailedMessage
        ) { list in
            self.list = list
        }
    }
}

private extension RewardRuleListModel {
    static let loadFailedMessage = "ごほうびを読めませんでした"

    func rules(isHidden: Bool) -> [RewardRule] {
        let rules = list?.rules ?? []
        return rules.filter { $0.isActive != isHidden }
    }
}

extension RewardRuleListModel: SettingsBoardModel {
    public func reload() async {
        await load()
    }

    public func saveOrder(_ ids: [RewardRule.ID]) async throws {
        let ids = ids + hidden.map(\.id)
        try await database.reorderRewardRules(ids, at: Date())
    }

    public func saveHidden(
        _ id: RewardRule.ID,
        isHidden: Bool
    ) async throws {
        try await database.setRewardRuleHidden(
            id,
            isHidden: isHidden,
            at: Date()
        )
    }

    public func remove(_ id: RewardRule.ID) async throws -> Deletion {
        try await database.deleteRewardRule(id)
    }

    public func restoreRemoved(_ deletion: Deletion) async throws {
        try await database.restore(deletion)
    }
}

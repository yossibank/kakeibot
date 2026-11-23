import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class RewardRuleEditModel {
    public var name = ""
    public private(set) var calculator = AmountCalculator()
    public internal(set) var isHidden = false
    public private(set) var hasLogs = false

    public internal(set) var errorNotice = ErrorNotice()

    public let icon = SettingsIconEditorModel(glyph: .giftbox)

    private(set) var baseline: RewardRuleDraft?

    let editingId: RewardRule.ID?

    private let database: AppDatabase

    public init(
        database: AppDatabase,
        editing id: RewardRule.ID? = nil
    ) {
        self.database = database
        self.editingId = id
        self.baseline = draft
    }
}

public extension RewardRuleEditModel {
    var amount: Int? {
        calculator.amount > 0 ? calculator.amount : nil
    }

    var draft: RewardRuleDraft {
        RewardRuleDraft(
            name: name,
            amount: calculator.amount,
            icon: icon.draft
        )
    }

    func press(_ key: AmountCalculator.Key) {
        calculator.press(key)
    }

    func load() async {
        guard let editingId else {
            return
        }

        do {
            let list = try await database.rewardRuleList()
            let rule = list.rules.first { $0.id == editingId }

            guard
                let rule,
                let saved = list.icons[rule.iconId]
            else {
                errorNotice.show(Self.loadFailedMessage)
                return
            }

            name = rule.name
            calculator = AmountCalculator(amount: rule.amount)

            icon.apply(saved)

            isHidden = !rule.isActive
            hasLogs = list.total(of: rule) != nil
            baseline = draft
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func save() async -> Bool {
        do {
            try await database.saveRewardRule(
                draft,
                editing: editingId,
                at: Date()
            )

            return true
        } catch {
            errorNotice.show(SettingsEditMessage.saveFailed, for: error)
            return false
        }
    }
}

private extension RewardRuleEditModel {
    static let loadFailedMessage = "決まりを読めませんでした"
}

extension RewardRuleEditModel: SettingsEditRemoving {
    var edited: RewardRuleDraft {
        draft
    }

    var problemMessage: String? {
        draft.problems.first?.message
    }

    func remove(_ id: RewardRule.ID) async throws -> Deletion {
        try await database.deleteRewardRule(id)
    }

    func saveHidden(
        _ id: RewardRule.ID,
        isHidden: Bool
    ) async throws {
        try await database.setRewardRuleHidden(
            id,
            isHidden: isHidden,
            at: Date()
        )
    }
}

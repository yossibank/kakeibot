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
    public private(set) var isHidden = false

    public internal(set) var errorNotice = ErrorNotice()

    public let icon = IconEditModel(glyph: .giftbox)

    private var baseline: RewardRuleDraft?

    private let database: AppDatabase
    private let editingId: RewardRule.ID?

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
    var isEditing: Bool {
        editingId != nil
    }

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

    var isChanged: Bool {
        baseline.map { $0 != draft } ?? false
    }

    var canSave: Bool {
        draft.problems.isEmpty
    }

    var saveTitle: String {
        SettingsSaveTitle.text(
            problem: draft.problems.first?.message,
            isEditing: isEditing
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
            errorNotice.show(Self.saveFailedMessage)

            return false
        }
    }

    func setHidden(_ isHidden: Bool) async -> Bool {
        guard let editingId else {
            return false
        }

        do {
            try await database.setRewardRuleHidden(
                editingId,
                isHidden: isHidden,
                at: Date()
            )

            self.isHidden = isHidden

            return true
        } catch {
            errorNotice.show(Self.saveFailedMessage)

            return false
        }
    }

    func delete() async -> Deletion? {
        guard let editingId else {
            return nil
        }

        do {
            return try await database.deleteRewardRule(editingId)
        } catch {
            errorNotice.show(Self.deleteFailedMessage)

            return nil
        }
    }
}

private extension RewardRuleEditModel {
    static let saveFailedMessage = "保存できませんでした"
    static let deleteFailedMessage = "削除できませんでした"
    static let loadFailedMessage = "ごほうびを読めませんでした"
}

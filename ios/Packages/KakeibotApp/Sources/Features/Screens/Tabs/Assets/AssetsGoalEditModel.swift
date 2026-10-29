import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class AssetsGoalEditModel {
    public var name: String

    public private(set) var calculator: AmountCalculator

    public internal(set) var errorNotice = ErrorNotice()

    private let baseline: RewardGoalDraft
    private let database: AppDatabase
    private let editing: RewardGoal?

    public init(
        database: AppDatabase,
        editing goal: RewardGoal? = nil
    ) {
        let name = goal?.name ?? ""
        let amount = goal?.targetAmount ?? 0

        self.database = database
        self.editing = goal
        self.name = name
        self.calculator = AmountCalculator(amount: amount)
        self.baseline = RewardGoalDraft(name: name, targetAmount: amount)
    }
}

public extension AssetsGoalEditModel {
    var isEditing: Bool {
        editing != nil
    }

    var draft: RewardGoalDraft {
        RewardGoalDraft(name: name, targetAmount: calculator.amount)
    }

    var isChanged: Bool {
        draft != baseline
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

    func save() async -> Bool {
        do {
            try await database.saveRewardGoal(
                draft,
                editing: editing?.id,
                at: Date()
            )

            return true
        } catch {
            errorNotice.show(Self.saveFailedMessage, for: error)
            return false
        }
    }

    func delete() async -> Bool {
        guard let editing else {
            return false
        }

        do {
            try await database.deleteRewardGoal(editing.id)
            return true
        } catch {
            errorNotice.show(Self.deleteFailedMessage, for: error)
            return false
        }
    }
}

private extension AssetsGoalEditModel {
    static let saveFailedMessage = "目標を保存できませんでした"
    static let deleteFailedMessage = "目標を削除できませんでした"
}

import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class AssetsRewardGoalEditModel {
    public let state: State
    public let input: Input
    public let output: Output

    let dependencies: ScreenParts

    public init(
        parts: ScreenParts,
        editing goal: RewardGoal? = nil,
        balance: Int = 0
    ) {
        let name = goal?.name ?? ""
        let amount = goal?.targetAmount ?? 0
        let state = State(name: name, amount: amount)

        let input = Input(
            baseline: RewardGoalDraft(name: name, targetAmount: amount),
            editing: goal,
            balance: balance
        )

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = parts
    }
}

public extension AssetsRewardGoalEditModel {
    @MainActor
    @Observable
    final class State: NoticeHolding {
        public var errorNotice = ErrorNotice()

        public var name: String

        public private(set) var calculator: AmountCalculator

        init(
            name: String,
            amount: Int
        ) {
            self.name = name
            self.calculator = AmountCalculator(amount: amount)
        }

        public func press(_ key: AmountCalculator.Key) {
            calculator.press(key)
        }
    }

    @MainActor
    @Observable
    final class Input {
        let baseline: RewardGoalDraft
        let editing: RewardGoal?
        let balance: Int

        init(
            baseline: RewardGoalDraft,
            editing: RewardGoal?,
            balance: Int
        ) {
            self.baseline = baseline
            self.editing = editing
            self.balance = balance
        }
    }

    @MainActor
    final class Output {
        let input: Input
        let state: State

        public var isEditing: Bool {
            input.editing != nil
        }

        public var draft: RewardGoalDraft {
            RewardGoalDraft(name: state.name, targetAmount: state.calculator.amount)
        }

        public var isChanged: Bool {
            draft != input.baseline
        }

        public var canSave: Bool {
            draft.problems.isEmpty
        }

        public var remaining: Int {
            max(state.calculator.amount - input.balance, 0)
        }

        public var progress: Double {
            guard state.calculator.amount > 0 else {
                return 0
            }

            return Double(input.balance) / Double(state.calculator.amount)
        }

        public var saveTitle: String {
            SettingsSaveTitle.text(
                problem: draft.problems.first?.message,
                isEditing: isEditing
            )
        }

        init(
            input: Input,
            state: State
        ) {
            self.input = input
            self.state = state
        }
    }

    func save() async -> Bool {
        do {
            try await dependencies.database.saveRewardGoal(
                output.draft,
                editing: input.editing?.id,
                at: dependencies.clock.now
            )

            return true
        } catch {
            state.errorNotice.show(Self.saveFailedMessage, for: error)
            return false
        }
    }

    func delete() async -> Bool {
        guard let editing = input.editing else {
            return false
        }

        do {
            try await dependencies.database.deleteRewardGoal(editing.id)
            return true
        } catch {
            state.errorNotice.show(Self.deleteFailedMessage, for: error)
            return false
        }
    }
}

private extension AssetsRewardGoalEditModel {
    static let saveFailedMessage = "目標を保存できませんでした"
    static let deleteFailedMessage = "目標を削除できませんでした"
}

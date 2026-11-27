import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class AssetsRewardGoalEditModel: ScreenPerforming {
    public let state: State
    public let input: Input
    public let output: Output
    public let flow: EditFlow<Void>

    let dependencies: ScreenParts

    public init(
        parts: ScreenParts,
        editing goal: RewardGoal? = nil,
        balance: Int = 0
    ) {
        let name = goal?.name ?? ""
        let amount = goal?.targetAmount ?? 0

        let state = State(
            name: name,
            amount: amount,
            panel: goal == nil ? .amount : nil,
            wait: parts.wait
        )

        let baseline = RewardGoalDraft(name: name, targetAmount: amount)
        let input = Input(editingId: goal?.id, baseline: baseline, balance: balance)
        let output = Output(input: input, state: state)
        let source = Source(state: state, input: input, output: output, parts: parts)

        self.state = state
        self.input = input
        self.output = output
        self.flow = EditFlow(source: source)
        self.dependencies = parts
    }
}

public extension AssetsRewardGoalEditModel {
    enum Panel: Hashable, Sendable {
        case amount
    }

    struct Fields: ScreenEditable {
        public var name: String
    }

    struct Presented: ScreenEditable {
        public var panel: Shown<Panel>
    }

    @MainActor
    struct Notices: ScreenNotices {
        public let error: ErrorNotice

        init(wait: ScreenWait) {
            self.error = ErrorNotice(wait: wait)
        }
    }

    @MainActor
    struct Submodels {
        public internal(set) var calculator: AmountCalculator
    }

    @MainActor
    @Observable
    final class State: NoticesHolding {
        public var fields: Fields
        public var presented: Presented

        public let notices: Notices

        public internal(set) var submodels: Submodels

        init(
            name: String,
            amount: Int,
            panel: Panel?,
            wait: ScreenWait
        ) {
            self.notices = Notices(wait: wait)
            self.presented = Presented(panel: Shown(panel))
            self.fields = Fields(name: name)
            self.submodels = Submodels(calculator: AmountCalculator(amount: amount))
        }
    }

    @MainActor
    @Observable
    final class Input {
        public let editingId: RewardGoal.ID?
        public let baseline: RewardGoalDraft

        let balance: Int

        init(
            editingId: RewardGoal.ID?,
            baseline: RewardGoalDraft,
            balance: Int
        ) {
            self.editingId = editingId
            self.baseline = baseline
            self.balance = balance
        }
    }

    @MainActor
    final class Output {
        let input: Input
        let state: State

        init(
            input: Input,
            state: State
        ) {
            self.input = input
            self.state = state
        }
    }
}

extension AssetsRewardGoalEditModel {
    @MainActor
    struct Source {
        let state: State
        let input: Input
        let output: Output
        let dependencies: ScreenParts

        init(
            state: State,
            input: Input,
            output: Output,
            parts: ScreenParts
        ) {
            self.state = state
            self.input = input
            self.output = output
            self.dependencies = parts
        }
    }
}

public extension AssetsRewardGoalEditModel {
    @discardableResult
    func save() async -> Void? {
        await source.store()
    }
}

extension AssetsRewardGoalEditModel {
    var source: Source {
        Source(state: state, input: input, output: output, parts: dependencies)
    }
}

private extension AssetsRewardGoalEditModel {
    static let saveFailedMessage = "目標を保存できませんでした"
    static let deleteFailedMessage = "目標を削除できませんでした"
}

public extension AssetsRewardGoalEditModel.Output {
    var draft: RewardGoalDraft {
        RewardGoalDraft(name: state.fields.name, targetAmount: state.submodels.calculator.amount)
    }

    var remaining: Int {
        max(state.submodels.calculator.amount - input.balance, 0)
    }

    var progress: Double {
        guard state.submodels.calculator.amount > 0 else {
            return 0
        }

        return Double(input.balance) / Double(state.submodels.calculator.amount)
    }
}

public extension AssetsRewardGoalEditModel.State {
    func press(_ key: AmountCalculator.Key) {
        submodels.calculator.press(key)
    }
}

extension AssetsRewardGoalEditModel.Source: EditFlowSource {
    var isEditing: Bool {
        input.editingId != nil
    }

    var isChanged: Bool {
        input.baseline != output.draft
    }

    var problem: String? {
        output.draft.problems.first?.message
    }

    func store() async -> Void? {
        do {
            try await dependencies.database.saveRewardGoal(
                output.draft,
                editing: input.editingId,
                at: dependencies.clock.now
            )

            return ()
        } catch {
            state.notices.error.show(AssetsRewardGoalEditModel.saveFailedMessage, for: error)
            return nil
        }
    }

    func remove() async throws -> Deletion? {
        guard let editingId = input.editingId else {
            return nil
        }

        try await dependencies.database.deleteRewardGoal(editingId)

        return nil
    }

    func deleteFailedMessage(for _: any Error) -> String {
        AssetsRewardGoalEditModel.deleteFailedMessage
    }
}

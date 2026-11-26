import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class RewardRuleEditModel {
    public let state: State
    public let input: Input
    public let output: Output

    let dependencies: ScreenParts

    public init(
        parts: ScreenParts,
        editing id: RewardRule.ID? = nil
    ) {
        let state = State()
        let input = Input(editingId: id)
        let output = Output(state: state)

        input.baseline = output.draft

        self.state = state
        self.input = input
        self.output = output
        self.dependencies = parts
    }
}

public extension RewardRuleEditModel {
    enum Panel: Hashable, Sendable {
        case amount
    }

    @MainActor
    @Observable
    final class State: SettingsEditState {
        public var errorNotice = ErrorNotice()
        public var prompt = SettingsEditPrompt<Panel>()
        public var outcome = ScreenOutcome<SettingsEditOutcome<Void>>()
        public var name = ""

        public private(set) var calculator = AmountCalculator()

        public let icon = SettingsIconEditorModel(glyph: .giftbox)
    }

    @MainActor
    @Observable
    final class Input: SettingsEditHidingInput {
        public internal(set) var isHidden = false
        public internal(set) var hasLogs = false
        public internal(set) var baseline: RewardRuleDraft?

        public let editingId: RewardRule.ID?

        init(editingId: RewardRule.ID?) {
            self.editingId = editingId
        }
    }

    @MainActor
    final class Output {
        let state: State

        init(state: State) {
            self.state = state
        }
    }
}

public extension RewardRuleEditModel {
    func load() async {
        guard let editingId = input.editingId else {
            return
        }

        do {
            let list = try await dependencies.database.rewardRuleList()
            let rule = list.rules.first { $0.id == editingId }

            guard
                let rule,
                let saved = list.icons[rule.iconId]
            else {
                state.errorNotice.show(Self.loadFailedMessage)
                return
            }

            state.apply(rule, icon: saved)
            input.isHidden = !rule.isActive
            input.hasLogs = list.total(of: rule) != nil
            input.baseline = output.draft
        } catch {
            state.errorNotice.show(Self.loadFailedMessage)
        }
    }

    @discardableResult
    func save() async -> Bool {
        do {
            try await dependencies.database.save(
                output.draft,
                editing: input.editingId,
                at: dependencies.clock.now
            )

            await finishSave()

            return true
        } catch {
            state.errorNotice.show(SettingsEditMessage.saveFailed, for: error)
            return false
        }
    }
}

private extension RewardRuleEditModel {
    static let loadFailedMessage = "決まりを読めませんでした"
}

public extension RewardRuleEditModel.Output {
    var amount: Int? {
        state.calculator.amount > 0 ? state.calculator.amount : nil
    }

    var draft: RewardRuleDraft {
        RewardRuleDraft(
            name: state.name,
            amount: state.calculator.amount,
            icon: state.icon.draft
        )
    }
}

public extension RewardRuleEditModel.State {
    func press(_ key: AmountCalculator.Key) {
        calculator.press(key)
    }
}

extension RewardRuleEditModel.State {
    func apply(
        _ rule: RewardRule,
        icon saved: Icon
    ) {
        name = rule.name
        calculator = AmountCalculator(amount: rule.amount)
        icon.apply(saved)
    }
}

extension RewardRuleEditModel: SettingsEditRemoving {
    public var edited: RewardRuleDraft {
        output.draft
    }

    public var problemMessage: String? {
        output.draft.problems.first?.message
    }

    public func remove(_ id: RewardRule.ID) async throws -> Deletion {
        try await dependencies.database.deleteRewardRule(id)
    }

    public func saveHidden(
        _ id: RewardRule.ID,
        isHidden: Bool
    ) async throws {
        try await dependencies.database.setHidden(
            id,
            isHidden: isHidden,
            at: dependencies.clock.now
        )

        input.isHidden = isHidden
    }
}

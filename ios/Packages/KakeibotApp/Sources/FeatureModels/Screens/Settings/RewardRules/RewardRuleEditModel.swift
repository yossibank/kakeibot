import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class RewardRuleEditModel: ScreenPerforming {
    public let state: State
    public let input: Input
    public let output: Output
    public let flow: EditFlow<Void>

    let dependencies: ScreenParts

    public init(
        parts: ScreenParts,
        editing id: RewardRule.ID? = nil
    ) {
        let state = State()
        let output = Output(state: state)
        let input = Input(editingId: id, baseline: output.draft)
        let source = Source(state: state, input: input, output: output, parts: parts)

        self.state = state
        self.input = input
        self.output = output
        self.flow = EditFlow(source: source)
        self.dependencies = parts
    }
}

public extension RewardRuleEditModel {
    enum Panel: Hashable, Sendable {
        case amount
    }

    struct Fields: ScreenEditable {
        public var name = ""
    }

    @MainActor
    @Observable
    final class State: NoticeHolding {
        public var errorNotice = ErrorNotice()
        public var panel = Shown<Panel>()
        public var fields = Fields()

        public private(set) var calculator = AmountCalculator()

        public let icon = SettingsIconEditorModel(glyph: .giftbox)
    }

    @MainActor
    @Observable
    final class Input {
        public internal(set) var hasLogs = false
        public internal(set) var baseline: RewardRuleDraft?
        public internal(set) var isHidden = false

        public let editingId: RewardRule.ID?

        init(
            editingId: RewardRule.ID?,
            baseline: RewardRuleDraft
        ) {
            self.editingId = editingId
            self.baseline = baseline
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

extension RewardRuleEditModel {
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
            input.hasLogs = list.total(of: rule) != nil
            input.isHidden = !rule.isActive
            input.baseline = output.draft
        } catch {
            state.errorNotice.show(Self.loadFailedMessage)
        }
    }

    @discardableResult
    func save() async -> Void? {
        await source.store()
    }
}

extension RewardRuleEditModel {
    var source: Source {
        Source(state: state, input: input, output: output, parts: dependencies)
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
            name: state.fields.name,
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
        fields.name = rule.name
        calculator = AmountCalculator(amount: rule.amount)
        icon.apply(saved)
    }
}

extension RewardRuleEditModel.Source: EditFlowSource {
    var isEditing: Bool {
        input.editingId != nil
    }

    var isChanged: Bool {
        input.baseline.map { $0 != output.draft } ?? false
    }

    var problem: String? {
        output.draft.problems.first?.message
    }

    var isHidden: Bool {
        input.isHidden
    }

    func store() async -> Void? {
        do {
            try await dependencies.database.save(
                output.draft,
                editing: input.editingId,
                at: dependencies.clock.now
            )

            return ()
        } catch {
            state.errorNotice.show(SettingsEditMessage.saveFailed, for: error)
            return nil
        }
    }

    func storeHidden(_ isHidden: Bool) async throws {
        guard let editingId = input.editingId else {
            return
        }

        try await dependencies.database.setHidden(
            editingId,
            isHidden: isHidden,
            at: dependencies.clock.now
        )

        input.isHidden = isHidden
    }

    func remove() async throws -> Deletion? {
        guard let editingId = input.editingId else {
            return nil
        }

        return try await dependencies.database.deleteRewardRule(editingId)
    }
}

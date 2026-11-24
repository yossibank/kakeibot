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

    let dependencies: Dependencies

    public init(
        database: AppDatabase,
        clock: ScreenClock,
        editing id: RewardRule.ID? = nil
    ) {
        let state = State()
        let input = Input(editingId: id)
        let output = Output(state: state)

        input.baseline = output.draft

        self.state = state
        self.input = input
        self.output = output
        self.dependencies = Dependencies(database: database, clock: clock)
    }
}

public extension RewardRuleEditModel {
    @MainActor
    @Observable
    final class State: NoticeHolding {
        public internal(set) var errorNotice = ErrorNotice()

        public var name = ""

        public private(set) var calculator = AmountCalculator()

        public let icon = SettingsIconEditorModel(glyph: .giftbox)

        public func press(_ key: AmountCalculator.Key) {
            calculator.press(key)
        }

        func apply(
            _ rule: RewardRule,
            icon saved: Icon
        ) {
            name = rule.name
            calculator = AmountCalculator(amount: rule.amount)

            icon.apply(saved)
        }
    }

    @MainActor
    @Observable
    final class Input: SettingsEditHidingInput {
        public internal(set) var isHidden = false
        public internal(set) var hasLogs = false

        var baseline: RewardRuleDraft?

        let editingId: RewardRule.ID?

        init(editingId: RewardRule.ID?) {
            self.editingId = editingId
        }
    }

    @MainActor
    final class Output {
        let state: State

        public var amount: Int? {
            state.calculator.amount > 0 ? state.calculator.amount : nil
        }

        public var draft: RewardRuleDraft {
            RewardRuleDraft(
                name: state.name,
                amount: state.calculator.amount,
                icon: state.icon.draft
            )
        }

        init(state: State) {
            self.state = state
        }
    }

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

    func save() async -> Bool {
        do {
            try await dependencies.database.save(
                output.draft,
                editing: input.editingId,
                at: dependencies.clock.now
            )

            return true
        } catch {
            state.errorNotice.show(SettingsEditMessage.saveFailed, for: error)
            return false
        }
    }
}

extension RewardRuleEditModel {
    struct Dependencies {
        let database: AppDatabase
        let clock: ScreenClock
    }
}

private extension RewardRuleEditModel {
    static let loadFailedMessage = "決まりを読めませんでした"
}

extension RewardRuleEditModel: SettingsEditGroups, SettingsEditRemoving {
    var edited: RewardRuleDraft {
        output.draft
    }

    var problemMessage: String? {
        output.draft.problems.first?.message
    }

    func remove(_ id: RewardRule.ID) async throws -> Deletion {
        try await dependencies.database.deleteRewardRule(id)
    }

    func saveHidden(
        _ id: RewardRule.ID,
        isHidden: Bool
    ) async throws {
        try await dependencies.database.setHidden(
            id,
            isHidden: isHidden,
            at: dependencies.clock.now
        )
    }
}

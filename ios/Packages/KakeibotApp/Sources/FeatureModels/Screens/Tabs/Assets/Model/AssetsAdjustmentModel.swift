import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class AssetsAdjustmentModel: ScreenPerforming {
    public let state: State
    public let input: Input
    public let output: Output
    public let flow: EditFlow<Void>

    let dependencies: ScreenParts

    public init(
        parts: ScreenParts,
        wallet: Wallet,
        balance: Int,
        today: LocalDate
    ) {
        let state = State(wait: parts.wait)
        let input = Input(wallet: wallet, balance: balance, today: today)
        let output = Output(input: input, state: state)
        let source = Source(state: state, input: input, output: output, parts: parts)

        self.state = state
        self.input = input
        self.output = output
        self.flow = EditFlow(source: source)
        self.dependencies = parts
    }
}

public extension AssetsAdjustmentModel {
    @MainActor
    @Observable
    final class State: NoticeHolding {
        public let errorNotice: ErrorNotice

        public private(set) var calculator = AmountCalculator()

        init(wait: ScreenWait) {
            self.errorNotice = ErrorNotice(wait: wait)
        }
    }

    @MainActor
    @Observable
    final class Input {
        public let wallet: Wallet
        public let balance: Int

        let today: LocalDate

        init(
            wallet: Wallet,
            balance: Int,
            today: LocalDate
        ) {
            self.wallet = wallet
            self.balance = balance
            self.today = today
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

extension AssetsAdjustmentModel {
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

public extension AssetsAdjustmentModel {
    @discardableResult
    func save() async -> Void? {
        await source.store()
    }
}

extension AssetsAdjustmentModel {
    var source: Source {
        Source(state: state, input: input, output: output, parts: dependencies)
    }
}

private extension AssetsAdjustmentModel {
    static let saveFailedMessage = "残高を合わせられませんでした"
}

public extension AssetsAdjustmentModel.Output {
    var difference: Int {
        state.calculator.amount - input.balance
    }

    var canSave: Bool {
        difference != 0
    }

    var differenceText: String {
        canSave ? Yen.text(difference, type: .income) : "なし"
    }

    var differenceNote: String {
        canSave ? "差は今日の記録に入ります" : "記録の残高と同じです"
    }

    var saveTitle: String {
        canSave ? "\(differenceText) で合わせる" : "合わせる"
    }
}

public extension AssetsAdjustmentModel.State {
    func press(_ key: AmountCalculator.Key) {
        calculator.press(key)
    }
}

extension AssetsAdjustmentModel.Source: EditFlowSource {
    var isEditing: Bool {
        false
    }

    var isChanged: Bool {
        state.calculator.amount != 0
    }

    var problem: String? {
        output.canSave ? nil : output.differenceNote
    }

    func store() async -> Void? {
        guard output.canSave else {
            return nil
        }

        do {
            try await dependencies.database.saveAdjustment(
                output.difference,
                of: input.wallet.id,
                on: input.today,
                at: dependencies.clock.now
            )

            return ()
        } catch {
            state.errorNotice.show(AssetsAdjustmentModel.saveFailedMessage, for: error)
            return nil
        }
    }
}

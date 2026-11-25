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

    let dependencies: ScreenParts

    public init(
        parts: ScreenParts,
        wallet: Wallet,
        balance: Int,
        today: LocalDate
    ) {
        let state = State()
        let input = Input(
            wallet: wallet,
            balance: balance,
            today: today,
            openingAmount: state.calculator.amount
        )

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = parts
    }
}

public extension AssetsAdjustmentModel {
    @MainActor
    @Observable
    final class State: SettingsEditState {
        public var errorNotice = ErrorNotice()
        public var prompt = SettingsEditPrompt<Never>()
        public var outcome = ScreenOutcome<SettingsEditOutcome<Void>>()

        public private(set) var calculator = AmountCalculator()

        public func press(_ key: AmountCalculator.Key) {
            calculator.press(key)
        }
    }

    @MainActor
    @Observable
    final class Input {
        public let wallet: Wallet
        public let balance: Int

        let today: LocalDate
        let openingAmount: Int

        init(
            wallet: Wallet,
            balance: Int,
            today: LocalDate,
            openingAmount: Int
        ) {
            self.wallet = wallet
            self.balance = balance
            self.today = today
            self.openingAmount = openingAmount
        }
    }

    @MainActor
    final class Output {
        let input: Input
        let state: State

        public var difference: Int {
            state.calculator.amount - input.balance
        }

        public var canSave: Bool {
            difference != 0
        }

        public var isChanged: Bool {
            state.calculator.amount != input.openingAmount
        }

        public var differenceText: String {
            canSave ? Yen.text(difference, type: .income) : "なし"
        }

        public var differenceNote: String {
            canSave ? "差は今日の記録に入ります" : "記録の残高と同じです"
        }

        public var saveTitle: String {
            canSave ? "\(differenceText) で合わせる" : "合わせる"
        }

        init(
            input: Input,
            state: State
        ) {
            self.input = input
            self.state = state
        }
    }

    @discardableResult
    func save() async -> Bool {
        guard output.canSave else {
            return false
        }

        do {
            try await dependencies.database.saveAdjustment(
                output.difference,
                of: input.wallet.id,
                on: input.today,
                at: dependencies.clock.now
            )

            state.outcome.send(SettingsEditOutcome(saved: ()))

            return true
        } catch {
            state.errorNotice.show(Self.saveFailedMessage, for: error)
            return false
        }
    }
}

private extension AssetsAdjustmentModel {
    static let saveFailedMessage = "残高を合わせられませんでした"
}

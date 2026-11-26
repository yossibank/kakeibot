import Core
import DesignSystem
import Observation

public extension WalletEditModel {
    enum Drawer: Hashable, Sendable {
        case amount
        case valuation
        case loanAmount
    }

    struct Payment: Sendable {
        public var isAsking = false
        public var isEditing = false

        public internal(set) var addedWallet: Wallet?
    }

    @MainActor
    @Observable
    final class State: SettingsEditState {
        public var name = ""
        public var isNegative: Bool
        public var openValuationId: Valuation.ID?
        public var valuationDeletion: Deletion?
        public var payment = Payment()
        public var prompt = SettingsEditPrompt<Drawer>()
        public var outcome = ScreenOutcome<SettingsEditOutcome<Wallet>>()

        public private(set) var kind: Wallet.Kind
        public private(set) var calculator = AmountCalculator()
        public private(set) var loanAmount = AmountCalculator()

        public internal(set) var valuation = AmountCalculator()

        public var errorNotice = ErrorNotice()

        public let icon: SettingsIconEditorModel

        init(kind: Wallet.Kind) {
            self.kind = kind
            self.isNegative = kind.isDebt

            self.icon = SettingsIconEditorModel(
                glyph: WalletEditModel.glyph(for: kind),
                color: WalletEditModel.defaultColor
            )
        }
    }
}

public extension WalletEditModel.State {
    func setKind(_ kind: Wallet.Kind) {
        let oldKind = self.kind

        self.kind = kind

        if isNegative == oldKind.isDebt {
            isNegative = kind.isDebt
        }

        guard icon.markKind == .glyph, icon.glyph == WalletEditModel.glyph(for: oldKind) else {
            return
        }

        icon.glyph = WalletEditModel.glyph(for: kind)
    }

    func press(_ key: AmountCalculator.Key) {
        guard
            calculator.tokens.isEmpty,
            case let .operation(operation) = key,
            operation == .add || operation == .subtract
        else {
            calculator.press(key)
            return
        }

        isNegative = operation == .subtract
    }

    func pressValuation(_ key: AmountCalculator.Key) {
        valuation.press(key)
    }

    func pressLoanAmount(_ key: AmountCalculator.Key) {
        loanAmount.press(key)
    }
}

extension WalletEditModel.State {
    func apply(_ draft: WalletDraft) {
        name = draft.name
        kind = draft.kind
        icon.apply(draft.icon)
        isNegative = draft.initialBalance < 0
        calculator = AmountCalculator(amount: abs(draft.initialBalance))
        loanAmount = AmountCalculator(amount: draft.loanAmount ?? 0)
    }
}

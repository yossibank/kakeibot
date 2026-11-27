import Core
import DesignSystem
import Observation

public extension WalletEditModel {
    enum Drawer: Hashable, Sendable {
        case amount
        case valuation
        case loanAmount
    }

    enum PaymentStep: Hashable, Sendable {
        case asking
        case editing
    }

    struct Fields: ScreenEditable {
        public var name = ""
    }

    struct Presented: ScreenEditable {
        public var panel = Shown<Drawer>()
        public var openValuation = Shown<Valuation.ID>()
        public var paymentStep = Shown<PaymentStep>()
    }

    @MainActor
    @Observable
    final class State: NoticeHolding {
        public var fields = Fields()
        public var presented = Presented()

        public private(set) var kind: Wallet.Kind
        public private(set) var calculator = AmountCalculator()
        public private(set) var loanAmount = AmountCalculator()
        public private(set) var sign: BalanceSign

        public internal(set) var valuation = AmountCalculator()
        public internal(set) var addedWallet: Wallet?

        public let errorNotice: ErrorNotice
        public let icon: SettingsIconEditorModel
        public let valuationDeletion: UndoNotice<Deletion>

        init(
            kind: Wallet.Kind,
            wait: ScreenWait
        ) {
            self.errorNotice = ErrorNotice(wait: wait)
            self.kind = kind
            self.sign = BalanceSign(isNegative: kind.isDebt)
            self.valuationDeletion = UndoNotice(wait: wait)

            self.icon = SettingsIconEditorModel(
                glyph: WalletEditModel.glyph(for: kind),
                color: WalletEditModel.defaultColor
            )
        }
    }
}

public extension WalletEditModel.State {
    var isNegative: Bool {
        sign.isNegative
    }

    func setNegative(_ isNegative: Bool) {
        sign.set(isNegative)
    }

    func setKind(_ kind: Wallet.Kind) {
        let oldKind = self.kind

        self.kind = kind
        sign.follow(from: oldKind, to: kind)

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

        sign.set(operation == .subtract)
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
        fields.name = draft.name
        kind = draft.kind
        icon.apply(draft.icon)
        sign.set(draft.initialBalance < 0)
        calculator = AmountCalculator(amount: abs(draft.initialBalance))
        loanAmount = AmountCalculator(amount: draft.loanAmount ?? 0)
    }
}

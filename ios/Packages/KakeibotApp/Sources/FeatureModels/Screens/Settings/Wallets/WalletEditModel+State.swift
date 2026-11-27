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
    struct Notices: ScreenNotices {
        public let error: ErrorNotice
        public let valuationDeletion: UndoNotice<Deletion>

        init(wait: ScreenWait) {
            self.error = ErrorNotice(wait: wait)
            self.valuationDeletion = UndoNotice(wait: wait)
        }
    }

    @MainActor
    struct Submodels {
        public internal(set) var calculator = AmountCalculator()
        public internal(set) var loanAmount = AmountCalculator()
        public internal(set) var valuation = AmountCalculator()

        public let icon: SettingsIconEditorModel
    }

    @MainActor
    @Observable
    final class State: NoticesHolding {
        public var fields = Fields()
        public var presented = Presented()

        public private(set) var kind: Wallet.Kind
        public private(set) var sign: BalanceSign

        public internal(set) var addedWallet: Wallet?
        public internal(set) var submodels: Submodels

        public let notices: Notices

        init(
            kind: Wallet.Kind,
            wait: ScreenWait
        ) {
            self.notices = Notices(wait: wait)
            self.kind = kind
            self.sign = BalanceSign(isNegative: kind.isDebt)

            self.submodels = Submodels(
                icon: SettingsIconEditorModel(
                    glyph: WalletEditModel.glyph(for: kind),
                    color: WalletEditModel.defaultColor
                )
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

        let icon = submodels.icon

        guard icon.markKind == .glyph, icon.glyph == WalletEditModel.glyph(for: oldKind) else {
            return
        }

        icon.glyph = WalletEditModel.glyph(for: kind)
    }

    func press(_ key: AmountCalculator.Key) {
        guard
            submodels.calculator.tokens.isEmpty,
            case let .operation(operation) = key,
            operation == .add || operation == .subtract
        else {
            submodels.calculator.press(key)
            return
        }

        sign.set(operation == .subtract)
    }

    func pressValuation(_ key: AmountCalculator.Key) {
        submodels.valuation.press(key)
    }

    func pressLoanAmount(_ key: AmountCalculator.Key) {
        submodels.loanAmount.press(key)
    }
}

extension WalletEditModel.State {
    func apply(_ draft: WalletDraft) {
        fields.name = draft.name
        kind = draft.kind
        submodels.icon.apply(draft.icon)
        sign.set(draft.initialBalance < 0)
        submodels.calculator = AmountCalculator(amount: abs(draft.initialBalance))
        submodels.loanAmount = AmountCalculator(amount: draft.loanAmount ?? 0)
    }
}

import Core
import DesignSystem
import Observation

public extension TemplateEditModel {
    @MainActor
    @Observable
    final class State: SettingsEditState {
        public var errorNotice = ErrorNotice()
        public var prompt = SettingsEditPrompt()

        public var name = ""
        public var memo = ""
        public var billShift = 0

        public private(set) var walletId: Wallet.ID?
        public private(set) var categoryId: EntryCategory.ID?
        public private(set) var tagId: EntryTag.ID?
        public private(set) var type: Entry.Kind
        public private(set) var calculator = AmountCalculator()

        init(type: Entry.Kind) {
            self.type = type
        }
    }
}

public extension TemplateEditModel.State {
    func setWallet(_ id: Wallet.ID?) {
        guard id != walletId else {
            return
        }

        walletId = id
        billShift = 0
    }

    func setCategory(_ id: EntryCategory.ID?) {
        guard id != categoryId else {
            return
        }

        categoryId = id
        tagId = nil
    }

    func toggleTag(_ id: EntryTag.ID) {
        tagId = tagId == id ? nil : id
    }

    func press(_ key: AmountCalculator.Key) {
        calculator.press(key)
    }
}

extension TemplateEditModel.State {
    func apply(_ draft: EntryTemplateDraft) {
        name = draft.name
        type = draft.type
        calculator = AmountCalculator(amount: draft.amount ?? 0)
        categoryId = draft.categoryId
        tagId = draft.tagId
        walletId = draft.walletId
        memo = draft.memo
        billShift = draft.billShift
    }
}

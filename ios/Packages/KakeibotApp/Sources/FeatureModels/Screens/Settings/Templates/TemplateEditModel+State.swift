import Core
import DesignSystem
import Observation

public extension TemplateEditModel {
    enum Panel: Hashable, Sendable {
        case amount
        case tag
        case memo
    }

    struct Fields: ScreenEditable {
        public var name = ""
        public var memo = ""
        public var billShift = 0
        public var walletId: Wallet.ID?
        public var categoryId: EntryCategory.ID?
        public var tagId: EntryTag.ID?
    }

    struct Presented: ScreenEditable {
        public var panel = Shown<Panel>()
        public var tagCategory = Shown<EntryCategory>()
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
        public internal(set) var calculator = AmountCalculator()
    }

    @MainActor
    @Observable
    final class State: NoticesHolding {
        public var fields = Fields()
        public var presented = Presented()

        public internal(set) var submodels = Submodels()

        public private(set) var type: Entry.Kind

        public let notices: Notices

        init(
            type: Entry.Kind,
            wait: ScreenWait
        ) {
            self.notices = Notices(wait: wait)
            self.type = type
        }
    }
}

public extension TemplateEditModel.State {
    func setWallet(_ id: Wallet.ID?) {
        guard id != fields.walletId else {
            return
        }

        fields.walletId = id
        fields.billShift = 0
    }

    func setCategory(_ id: EntryCategory.ID?) {
        guard id != fields.categoryId else {
            return
        }

        fields.categoryId = id
        fields.tagId = nil
    }

    func toggleTag(_ id: EntryTag.ID) {
        fields.tagId = fields.tagId == id ? nil : id
    }

    func press(_ key: AmountCalculator.Key) {
        submodels.calculator.press(key)
    }
}

extension TemplateEditModel.State {
    func apply(_ draft: EntryTemplateDraft) {
        fields.name = draft.name
        type = draft.type
        submodels.calculator = AmountCalculator(amount: draft.amount ?? 0)
        fields.categoryId = draft.categoryId
        fields.tagId = draft.tagId
        fields.walletId = draft.walletId
        fields.memo = draft.memo
        fields.billShift = draft.billShift
    }
}

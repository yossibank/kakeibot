import Core
import DesignSystem
import Observation

public extension RecurringEditModel {
    struct Schedule: ScreenEditable {
        public var frequency: Recurring.Frequency = .monthly
        public var month: Int
        public var day: Int
        public var closingDay: Int?
        public var startDate: LocalDate
        public var endDate: LocalDate?
        public var remindDaysBefore: Int?
        public var isOpen = false

        public private(set) var holidayShift: HolidayShift = .none

        private(set) var isHolidayShiftChosen = false
    }

    struct Repayment: Equatable, Sendable {
        public internal(set) var countCalculator = AmountCalculator()

        public private(set) var isCountAuto = true

        private(set) var manualFinal: Int?
    }

    enum Panel: Hashable, Sendable {
        case amount
        case start
        case end
        case holiday
        case closing
        case fee
        case count
        case remind
    }

    struct Fields: ScreenEditable {
        public var memo = ""
        public var billShift = 0
        public var schedule: Schedule
        public var walletId: Wallet.ID?
        public var categoryId: EntryCategory.ID?
        public var toWalletId: Wallet.ID?
    }

    struct Presented: ScreenEditable {
        public var panel = Shown<Panel>()
    }

    struct Submodels {
        public internal(set) var amount = AmountCalculator()
        public internal(set) var fee = AmountCalculator()
    }

    @MainActor
    struct Notices: ScreenNotices {
        public let error: ErrorNotice

        init(wait: ScreenWait) {
            self.error = ErrorNotice(wait: wait)
        }
    }

    @MainActor
    @Observable
    final class State: NoticesHolding {
        public var fields: Fields
        public var presented = Presented()

        public internal(set) var repayment = Repayment()
        public internal(set) var submodels = Submodels()
        public internal(set) var type: Entry.Kind

        public let notices: Notices

        init(
            type: Entry.Kind,
            today: LocalDate,
            isScheduleOpen: Bool,
            wait: ScreenWait
        ) {
            self.notices = Notices(wait: wait)
            self.type = type

            self.fields = Fields(
                schedule: Schedule(
                    month: today.month,
                    day: today.day,
                    startDate: today,
                    isOpen: isScheduleOpen
                )
            )
        }
    }
}

extension RecurringEditModel.Repayment {
    mutating func useAutoCount() {
        isCountAuto = true
        manualFinal = nil
    }

    mutating func useManualCount(final amount: Int?) {
        isCountAuto = false
        manualFinal = amount
    }

    mutating func setCountAuto(_ isCountAuto: Bool) {
        self.isCountAuto = isCountAuto
    }

    mutating func load(final amount: Int?) {
        manualFinal = amount
    }
}

public extension RecurringEditModel.Schedule {
    mutating func choose(_ shift: HolidayShift) {
        holidayShift = shift
        isHolidayShiftChosen = true
    }
}

extension RecurringEditModel.Schedule {
    mutating func suggest(_ shift: HolidayShift) {
        guard !isHolidayShiftChosen else {
            return
        }

        holidayShift = shift
    }

    mutating func load(_ shift: HolidayShift) {
        holidayShift = shift
    }
}

public extension RecurringEditModel.State {
    func useAutoCount() {
        repayment.useAutoCount()
    }

    func setWallet(_ id: Wallet.ID?) {
        guard id != fields.walletId else {
            return
        }

        fields.walletId = id
        fields.billShift = 0
    }

    func selectDestination(_ id: Wallet.ID) {
        fields.toWalletId = id
    }

    func press(_ key: AmountCalculator.Key) {
        submodels.amount.press(key)
    }

    func pressFee(_ key: AmountCalculator.Key) {
        submodels.fee.press(key)
    }

    func setFee(_ amount: Int) {
        submodels.fee = AmountCalculator(amount: amount)
    }
}

extension RecurringEditModel.State {
    func apply(_ draft: RecurringDraft) {
        type = draft.type
        submodels.amount = AmountCalculator(amount: draft.amount)
        fields.categoryId = draft.categoryId
        fields.walletId = draft.walletId
        fields.toWalletId = draft.toWalletId
        fields.memo = draft.memo
        fields.schedule.frequency = draft.frequency
        fields.schedule.month = draft.month
        fields.schedule.day = draft.day
        fields.schedule.load(draft.holidayShift)
        fields.schedule.closingDay = draft.closingDay
        submodels.fee = AmountCalculator(amount: draft.fee)
        fields.billShift = draft.billShift
        fields.schedule.startDate = draft.startDate
        fields.schedule.endDate = draft.endDate
        fields.schedule.remindDaysBefore = draft.remindDaysBefore
    }
}

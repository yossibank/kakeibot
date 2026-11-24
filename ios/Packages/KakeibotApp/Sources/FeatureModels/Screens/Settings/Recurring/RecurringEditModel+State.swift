import Core
import DesignSystem
import Observation

public extension RecurringEditModel {
    struct Schedule {
        public var frequency: Recurring.Frequency = .monthly
        public var month: Int
        public var day: Int
        public var closingDay: Int?
        public var startDate: LocalDate
        public var endDate: LocalDate?
        public var remindDaysBefore: Int?

        public private(set) var holidayShift: HolidayShift = .none

        private(set) var isHolidayShiftChosen = false

        public mutating func choose(_ shift: HolidayShift) {
            holidayShift = shift
            isHolidayShiftChosen = true
        }

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

    struct Repayment {
        public internal(set) var countCalculator = AmountCalculator()

        public private(set) var isCountAuto = true

        private(set) var manualFinal: Int?

        public mutating func useAutoCount() {
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

    @MainActor
    @Observable
    final class State: NoticeHolding {
        public var errorNotice = ErrorNotice()

        public var categoryId: EntryCategory.ID?
        public var toWalletId: Wallet.ID?
        public var memo = ""
        public var billShift = 0
        public var isScheduleOpen: Bool
        public var schedule: Schedule

        public private(set) var walletId: Wallet.ID?
        public private(set) var calculator = AmountCalculator()
        public private(set) var feeCalculator = AmountCalculator()

        public internal(set) var type: Entry.Kind

        public var repayment = Repayment()

        init(
            type: Entry.Kind,
            today: LocalDate,
            isScheduleOpen: Bool
        ) {
            self.type = type
            self.isScheduleOpen = isScheduleOpen
            self.schedule = Schedule(month: today.month, day: today.day, startDate: today)
        }
    }
}

public extension RecurringEditModel.State {
    func setWallet(_ id: Wallet.ID?) {
        guard id != walletId else {
            return
        }

        walletId = id
        billShift = 0
    }

    func press(_ key: AmountCalculator.Key) {
        calculator.press(key)
    }

    func pressFee(_ key: AmountCalculator.Key) {
        feeCalculator.press(key)
    }

    func setFee(_ amount: Int) {
        feeCalculator = AmountCalculator(amount: amount)
    }
}

extension RecurringEditModel.State {
    func apply(_ draft: RecurringDraft) {
        type = draft.type
        calculator = AmountCalculator(amount: draft.amount)
        categoryId = draft.categoryId
        walletId = draft.walletId
        toWalletId = draft.toWalletId
        memo = draft.memo
        schedule.frequency = draft.frequency
        schedule.month = draft.month
        schedule.day = draft.day
        schedule.load(draft.holidayShift)
        schedule.closingDay = draft.closingDay
        feeCalculator = AmountCalculator(amount: draft.fee)
        billShift = draft.billShift
        schedule.startDate = draft.startDate
        schedule.endDate = draft.endDate
        schedule.remindDaysBefore = draft.remindDaysBefore
    }
}

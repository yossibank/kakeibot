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

        public internal(set) var holidayShift: HolidayShift = .none

        var isHolidayShiftChosen = false
    }

    struct Repayment {
        public internal(set) var countCalculator = AmountCalculator()
        public internal(set) var isCountAuto = true

        var manualFinal: Int?
    }

    @MainActor
    @Observable
    final class State: NoticeHolding {
        public internal(set) var errorNotice = ErrorNotice()

        public var categoryId: EntryCategory.ID?
        public var toWalletId: Wallet.ID?
        public var memo = ""
        public var billShift = 0
        public var isScheduleOpen: Bool
        public var schedule: Schedule

        public private(set) var walletId: Wallet.ID?

        public internal(set) var type: Entry.Kind
        public internal(set) var calculator = AmountCalculator()
        public internal(set) var feeCalculator = AmountCalculator()
        public internal(set) var repayment = Repayment()

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
        schedule.holidayShift = draft.holidayShift
        schedule.closingDay = draft.closingDay
        feeCalculator = AmountCalculator(amount: draft.fee)
        billShift = draft.billShift
        schedule.startDate = draft.startDate
        schedule.endDate = draft.endDate
        schedule.remindDaysBefore = draft.remindDaysBefore
    }
}

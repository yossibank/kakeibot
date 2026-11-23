import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class RecurringEditModel {
    public var categoryId: EntryCategory.ID?
    public var toWalletId: Wallet.ID?
    public var memo = ""
    public var frequency: Recurring.Frequency = .monthly
    public var month: Int
    public var day: Int
    public var closingDay: Int?
    public var startDate: LocalDate
    public var endDate: LocalDate?
    public var remindDaysBefore: Int?
    public var billShift = 0
    public var isScheduleOpen: Bool

    public var walletId: Wallet.ID? {
        didSet {
            if walletId != oldValue {
                billShift = 0
            }
        }
    }

    public internal(set) var type: Entry.Kind = .expense
    public internal(set) var holidayShift: HolidayShift = .none
    public internal(set) var calculator = AmountCalculator()
    public internal(set) var feeCalculator = AmountCalculator()
    public internal(set) var options: EntryOptions?
    public internal(set) var cardBills: [Recurring] = []
    public internal(set) var repayment = Repayment()
    public internal(set) var isHidden = false
    public internal(set) var authorization: NotificationAuthorization = .allowed
    public internal(set) var errorNotice = ErrorNotice()

    var baseline: RecurringDraft?
    var isHolidayShiftChosen = false

    let today: LocalDate
    let database: AppDatabase
    let editingId: Recurring.ID?
    let paidWallet: Wallet.ID?

    public init(
        database: AppDatabase,
        today: LocalDate,
        type: Entry.Kind = .expense,
        editing id: Recurring.ID? = nil,
        paying wallet: Wallet.ID? = nil
    ) {
        self.database = database
        self.today = today
        self.type = type
        self.editingId = id
        self.paidWallet = wallet
        self.month = today.month
        self.day = today.day
        self.startDate = today
        self.isScheduleOpen = id == nil
    }
}

public extension RecurringEditModel {
    static let remindChoices: [Int?] = [nil, 0, 1, 3, 7]
    static let destinationTitle = "振替先"

    var amount: Int {
        calculator.amount
    }

    var walletTitle: String {
        type.walletTitle
    }

    var draft: RecurringDraft {
        let closing = canUseClosingDay ? closingDay : nil
        let transferFee = type == .transfer ? fee : 0

        return RecurringDraft(
            type: type,
            amount: amount,
            categoryId: categoryId,
            walletId: walletId,
            toWalletId: toWalletId,
            memo: memo,
            frequency: frequency,
            month: month,
            day: day,
            holidayShift: holidayShift,
            closingDay: closing,
            fee: transferFee,
            finalAmount: finalAmount ?? 0,
            billShift: billRecurring == nil ? 0 : billShift,
            startDate: startDate,
            endDate: scheduledEndDate,
            remindDaysBefore: remindDaysBefore
        )
    }

    var billRecurring: Recurring? {
        type == .transfer ? nil : cardBills.cardBill(paidBy: walletId)
    }

    var billDates: [LocalDate] {
        guard
            let bill = billRecurring,
            let next = previewRow.next
        else {
            return []
        }

        return bill.billDates(for: next, count: Recurring.billChoiceCount)
    }

    var canUseClosingDay: Bool {
        type == .transfer && selectedDestination?.kind == .card
    }

    var fee: Int {
        feeCalculator.amount
    }

    var isCardBill: Bool {
        canUseClosingDay && closingDay != nil
    }

    var isLoanRepayment: Bool {
        type == .transfer && selectedDestination?.kind == .loan
    }

    var categories: [EntryCategory] {
        options?.categories(of: type) ?? []
    }

    var wallets: [Wallet] {
        options?.wallets ?? []
    }

    var selectedCategory: EntryCategory? {
        categories.first { $0.id == categoryId }
    }

    var selectedWallet: Wallet? {
        wallets.first { $0.id == walletId }
    }

    var selectedDestination: Wallet? {
        wallets.first { $0.id == toWalletId }
    }

    func icon(for category: EntryCategory) -> Icon? {
        options?.icon(for: category)
    }

    func icon(for wallet: Wallet) -> Icon? {
        options?.icon(for: wallet)
    }

    func select(_ type: Entry.Kind) {
        guard type != self.type else {
            return
        }

        self.type = type
        categoryId = categories.first?.id

        presetDestination()
        suggestHolidayShift()
    }

    func select(category id: EntryCategory.ID) {
        categoryId = id
        suggestHolidayShift()
    }

    func choose(_ shift: HolidayShift) {
        holidayShift = shift
        isHolidayShiftChosen = true
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

    func save(permission: NotificationPermission = .allowed) async -> Bool {
        if let problem = draft.problems.first {
            let text = message(for: problem)

            errorNotice.show(text)
            return false
        }

        do {
            try await database.saveRecurring(draft, editing: editingId, today: today, at: Date())

            await requestPermissionIfReminding(permission)

            return true
        } catch {
            errorNotice.show(SettingsEditMessage.saveFailed, for: error)
            return false
        }
    }
}

extension RecurringEditModel {
    func message(for problem: RecurringDraft.Problem) -> String {
        switch problem {
        case .amountNotPositive: "金額を入れてください"
        case .missingCategory: "カテゴリを選んでください"
        case .missingWallet: "\(walletTitle)を選んでください"
        case .missingDestination: "\(Self.destinationTitle)を選んでください"
        case .sameWallet: "振替元と振替先を別にしてください"
        case .endBeforeStart: "終わりを始まりより後にしてください"
        case .categoryOnTransfer, .dayOutOfRange, .closingDayOutOfRange,
             .monthOutOfRange, .remindOutOfRange, .feeNegative:
            SettingsEditMessage.saveFailed
        }
    }
}

private extension RecurringEditModel {
    func requestPermissionIfReminding(_ permission: NotificationPermission) async {
        guard remindDaysBefore != nil else {
            return
        }

        await permission.requestIfUndecided()
    }
}

extension RecurringEditModel: SettingsEditRemoving {
    static let deleteFailedMessage = SettingsEditMessage.saveFailed

    var edited: RecurringDraft {
        draft
    }

    var problemMessage: String? {
        draft.problems.first.map(message)
    }

    func remove(_ id: Recurring.ID) async throws -> Deletion {
        try await database.deleteRecurring(id, at: Date())
    }

    func saveHidden(
        _ id: Recurring.ID,
        isHidden: Bool
    ) async throws {
        try await database.setRecurringHidden(
            id,
            isHidden: isHidden,
            today: today,
            at: Date()
        )
    }
}

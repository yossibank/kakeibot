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

    public var walletId: Wallet.ID? {
        didSet {
            if walletId != oldValue {
                billShift = 0
            }
        }
    }

    public private(set) var holidayShift: HolidayShift = .none
    public private(set) var type: Entry.Kind = .expense
    public private(set) var calculator = AmountCalculator()
    public private(set) var feeCalculator = AmountCalculator()
    public private(set) var countCalculator = AmountCalculator()
    public private(set) var isCountAuto = true
    public private(set) var loanBalances: [Wallet.ID: Int] = [:]
    public private(set) var options: EntryOptions?
    public private(set) var cardBills: [Recurring] = []
    public private(set) var isHidden = false

    public internal(set) var authorization: NotificationAuthorization = .allowed
    public internal(set) var errorNotice = ErrorNotice()

    let today: LocalDate

    private var baseline: RecurringDraft?
    private var isHolidayShiftChosen = false
    private var manualFinal: Int?
    private var generatedUntil: LocalDate?

    private let database: AppDatabase
    private let editingId: Recurring.ID?
    private let paidWallet: Wallet.ID?

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
    }
}

public extension RecurringEditModel {
    static let remindChoices: [Int?] = [nil, 0, 1, 3, 7]
    static let destinationTitle = "振替先"

    var isEditing: Bool {
        editingId != nil
    }

    var amount: Int {
        calculator.amount
    }

    var walletTitle: String {
        switch type {
        case .expense: "支払い元"
        case .income: "入金先"
        case .transfer: "振替元"
        }
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

    var loanOwed: Int? {
        guard
            isLoanRepayment,
            let id = toWalletId,
            let balance = loanBalances[id],
            balance < 0
        else {
            return nil
        }

        return -balance
    }

    var autoPlan: RepaymentPlan? {
        loanOwed.flatMap { RepaymentPlan(owed: $0, amount: amount) }
    }

    var usesAutoCount: Bool {
        isCountAuto && autoPlan != nil
    }

    var repaymentStart: LocalDate {
        let next = generatedUntil.map { $0.adding(days: 1) } ?? startDate
        return max(startDate, next)
    }

    var scheduledEndDate: LocalDate? {
        guard
            usesAutoCount,
            let plan = autoPlan
        else {
            return endDate
        }

        return autoEndDate(of: plan)
    }

    var finalAmount: Int? {
        guard isLoanRepayment else {
            return nil
        }

        return usesAutoCount ? autoPlan?.finalAmount : manualFinal
    }

    var plannedRecurring: Recurring {
        recurring(endDate: scheduledEndDate, finalAmount: finalAmount)
    }

    var repaymentCount: Int? {
        scheduledEndDate.map { end in
            plannedRecurring.dates(from: repaymentStart, through: end).count
        }
    }

    var plannedTotal: Int? {
        let planned = plannedRecurring

        return scheduledEndDate.map { end in
            planned.dates(from: repaymentStart, through: end)
                .map(planned.scheduledAmount(paidOn:))
                .reduce(0, +)
        }
    }

    var balanceGap: Int? {
        guard
            let owed = loanOwed,
            let total = plannedTotal,
            total != owed
        else {
            return nil
        }

        return total - owed
    }

    var canSave: Bool {
        draft.problems.isEmpty
    }

    var saveTitle: String {
        let problem = draft.problems.first.map(message)
        return SettingsSaveTitle.text(problem: problem, isEditing: isEditing)
    }

    var isChanged: Bool {
        baseline.map { $0 != draft } ?? false
    }

    var categories: [EntryCategory] {
        switch type {
        case .expense: options?.expenseCategories ?? []
        case .income: options?.incomeCategories ?? []
        case .transfer: []
        }
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
        options?.icons[category.iconId]
    }

    func icon(for wallet: Wallet) -> Icon? {
        options?.icons[wallet.iconId]
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

    func prepareCount() {
        countCalculator = AmountCalculator(amount: repaymentCount ?? 0)
    }

    func pressCount(_ key: AmountCalculator.Key) {
        countCalculator.press(key)

        if countCalculator.amount > Recurring.maxCount {
            countCalculator = AmountCalculator(amount: Recurring.maxCount)
        }

        let count = countCalculator.amount
        let end = recurring(endDate: nil, finalAmount: nil).endDate(
            afterCount: count,
            from: repaymentStart
        )

        setEnd(end)
    }

    func setEnd(_ date: LocalDate?) {
        isCountAuto = false
        endDate = date
        manualFinal = manualFinalAmount(through: date)
    }

    func useAutoCount() {
        isCountAuto = true
        manualFinal = nil
    }

    func load() async {
        do {
            options = try await database.entryOptions()
            cardBills = try await database.recurrings()

            try await loadLoanBalances()
            try await loadRecurring()
            presetPayment()

            if categoryId == nil {
                categoryId = categories.first?.id
            }

            suggestHolidayShift()

            if walletId == nil {
                walletId = wallets.first?.id
            }

            presetDestination()
            chooseCountMode()
            baseline = draft
        } catch is CancellationError {
            return
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
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
            errorNotice.show(Self.saveFailedMessage, for: error)
            return false
        }
    }

    func delete() async -> Deletion? {
        guard let editingId else {
            return nil
        }

        do {
            return try await database.deleteRecurring(editingId, at: Date())
        } catch {
            errorNotice.show(Self.saveFailedMessage, for: error)
            return nil
        }
    }

    func setHidden(_ isHidden: Bool) async -> Bool {
        guard let editingId else {
            return false
        }

        do {
            try await database.setRecurringHidden(
                editingId,
                isHidden: isHidden,
                today: today,
                at: Date()
            )

            self.isHidden = isHidden

            return true
        } catch {
            errorNotice.show(Self.saveFailedMessage, for: error)
            return false
        }
    }
}

private extension RecurringEditModel {
    static let billClosingDay = 31
    static let billPaymentDay = 27
    static let loadFailedMessage = "固定費を読めませんでした"
    static let saveFailedMessage = "保存できませんでした"

    var suggestedHolidayShift: HolidayShift {
        guard type != .transfer else {
            return .next
        }

        let glyph = selectedCategory.flatMap { icon(for: $0) }?.glyph

        switch glyph {
        case .salary, .bonus: return .previous
        case .home, .utility, .phone: return .next
        default: return .none
        }
    }

    func recurring(
        endDate: LocalDate?,
        finalAmount: Int?
    ) -> Recurring {
        Recurring(
            type: type,
            amount: amount,
            categoryId: nil,
            walletId: walletId ?? Wallet.ID(),
            toWalletId: toWalletId,
            frequency: frequency,
            month: frequency == .yearly ? month : nil,
            day: day,
            holidayShift: holidayShift,
            finalAmount: finalAmount,
            startDate: startDate,
            endDate: endDate,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func autoEndDate(of plan: RepaymentPlan) -> LocalDate? {
        recurring(endDate: nil, finalAmount: nil).endDate(
            afterCount: plan.count,
            from: repaymentStart
        )
    }

    func manualFinalAmount(through end: LocalDate?) -> Int? {
        guard
            let end,
            let owed = loanOwed
        else {
            return nil
        }

        let count = recurring(endDate: end, finalAmount: nil)
            .dates(from: repaymentStart, through: end)
            .count

        return RepaymentPlan(owed: owed, amount: amount, count: count)?.finalAmount
    }

    func chooseCountMode() {
        guard isEditing else {
            isCountAuto = true
            return
        }

        guard
            let plan = autoPlan,
            let end = endDate
        else {
            isCountAuto = false
            return
        }

        isCountAuto = autoEndDate(of: plan) == end && plan.finalAmount == manualFinal
    }

    func loadLoanBalances() async throws {
        let list = try await database.latestEntryList()
        let entries = list.days.flatMap(\.entries)

        let pairs = wallets
            .filter { $0.kind == .loan }
            .map { wallet in
                let balance = wallet.balance(
                    with: entries,
                    valuations: list.valuations,
                    through: today
                )

                return (wallet.id, balance)
            }

        loanBalances = Dictionary(uniqueKeysWithValues: pairs)
    }

    func requestPermissionIfReminding(_ permission: NotificationPermission) async {
        guard remindDaysBefore != nil else {
            return
        }

        await permission.requestIfUndecided()
    }

    func presetPayment() {
        guard
            !isEditing,
            let target = paidWallet
        else {
            return
        }

        let bank = wallets.first { $0.kind == .bank && $0.id != target }
        let other = wallets.first { $0.id != target }

        type = .transfer
        categoryId = nil
        toWalletId = target
        walletId = (bank ?? other)?.id
        day = Self.billPaymentDay

        let name = selectedDestination?.name ?? ""

        if selectedDestination?.kind == .card {
            closingDay = Self.billClosingDay
            memo = name
        } else {
            memo = "\(name)の返済"
        }
    }

    func presetDestination() {
        guard
            type == .transfer,
            toWalletId == nil
        else {
            return
        }

        toWalletId = wallets.first { $0.id != walletId }?.id
    }

    func suggestHolidayShift() {
        guard
            !isEditing,
            !isHolidayShiftChosen
        else {
            return
        }

        holidayShift = suggestedHolidayShift
    }

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
            Self.saveFailedMessage
        }
    }

    func loadRecurring() async throws {
        guard let editingId else {
            return
        }

        let recurrings = try await database.recurrings(includingHidden: true)
        let recurring = recurrings.first { $0.id == editingId }

        guard let recurring else {
            throw AppDatabase.RecurringWriteError.recurringNotFound
        }

        let draft = RecurringDraft(recurring)

        isHidden = recurring.archivedAt != nil
        type = draft.type
        calculator = AmountCalculator(amount: draft.amount)
        categoryId = draft.categoryId
        walletId = draft.walletId
        toWalletId = draft.toWalletId
        memo = draft.memo
        frequency = draft.frequency
        month = draft.month
        day = draft.day
        holidayShift = draft.holidayShift
        closingDay = draft.closingDay
        feeCalculator = AmountCalculator(amount: draft.fee)
        manualFinal = recurring.finalAmount
        generatedUntil = recurring.generatedUntil
        billShift = draft.billShift
        startDate = draft.startDate
        endDate = draft.endDate
        remindDaysBefore = draft.remindDaysBefore
    }
}

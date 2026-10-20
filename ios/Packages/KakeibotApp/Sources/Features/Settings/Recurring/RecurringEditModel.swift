import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class RecurringEditModel {
    public var categoryId: EntryCategory.ID?
    public var walletId: Wallet.ID?
    public var toWalletId: Wallet.ID?
    public var memo = ""
    public var frequency: Recurring.Frequency = .monthly
    public var month: Int
    public var day: Int
    public private(set) var holidayShift: Recurring.HolidayShift = .none
    public var closingDay: Int?
    public var startDate: LocalDate
    public var endDate: LocalDate?
    public var remindDaysBefore: Int?

    public private(set) var type: Entry.Kind = .expense
    public private(set) var calculator = AmountCalculator()
    public private(set) var options: EntryOptions?

    public internal(set) var errorNotice = ErrorNotice()

    let today: LocalDate

    private var baseline: RecurringDraft?
    private var isHolidayShiftChosen = false

    private let database: AppDatabase
    private let editingId: Recurring.ID?

    public init(
        database: AppDatabase,
        today: LocalDate,
        editing id: Recurring.ID? = nil
    ) {
        self.database = database
        self.today = today
        self.editingId = id
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
        RecurringDraft(
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
            closingDay: canUseClosingDay ? closingDay : nil,
            startDate: startDate,
            endDate: endDate,
            remindDaysBefore: remindDaysBefore
        )
    }

    var canUseClosingDay: Bool {
        type == .transfer && selectedDestination?.kind == .card
    }

    var isCardBill: Bool {
        canUseClosingDay && closingDay != nil
    }

    var canSave: Bool {
        draft.problems.isEmpty
    }

    var saveTitle: String {
        SettingsSaveTitle.text(
            problem: draft.problems.first.map(message),
            isEditing: isEditing
        )
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

        if type == .transfer, toWalletId == nil {
            toWalletId = wallets.first { $0.id != walletId }?.id
        }

        suggestHolidayShift()
    }

    func select(category id: EntryCategory.ID) {
        categoryId = id
        suggestHolidayShift()
    }

    func choose(_ shift: Recurring.HolidayShift) {
        holidayShift = shift
        isHolidayShiftChosen = true
    }

    func press(_ key: AmountCalculator.Key) {
        calculator.press(key)
    }

    func load() async {
        do {
            options = try await database.entryOptions()
            try await loadRecurring()

            if categoryId == nil {
                categoryId = categories.first?.id
            }

            suggestHolidayShift()

            if walletId == nil {
                walletId = wallets.first?.id
            }

            baseline = draft
        } catch is CancellationError {
            return
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func save() async -> Bool {
        if let problem = draft.problems.first {
            errorNotice.show(message(for: problem))
            return false
        }

        do {
            try await database.saveRecurring(
                draft,
                editing: editingId,
                today: today,
                at: Date()
            )

            return true
        } catch {
            errorNotice.show(Self.saveFailedMessage)
            return false
        }
    }

    func delete() async -> Bool {
        guard let editingId else {
            return false
        }

        do {
            try await database.deleteRecurring(editingId)
            return true
        } catch {
            errorNotice.show(Self.saveFailedMessage)
            return false
        }
    }
}

private extension RecurringEditModel {
    var suggestedHolidayShift: Recurring.HolidayShift {
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

    func suggestHolidayShift() {
        guard !isEditing, !isHolidayShiftChosen else {
            return
        }

        holidayShift = suggestedHolidayShift
    }

    static let loadFailedMessage = "固定費を読めませんでした"
    static let saveFailedMessage = "保存できませんでした"

    func message(for problem: RecurringDraft.Problem) -> String {
        switch problem {
        case .amountNotPositive: "金額を入れてください"
        case .missingCategory: "カテゴリを選んでください"
        case .missingWallet: "\(walletTitle)を選んでください"
        case .missingDestination: "\(Self.destinationTitle)を選んでください"
        case .sameWallet: "振替元と振替先を別にしてください"
        case .endBeforeStart: "終わりを始まりより後にしてください"
        case .categoryOnTransfer, .dayOutOfRange, .closingDayOutOfRange,
             .monthOutOfRange, .remindOutOfRange:
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
        startDate = draft.startDate
        endDate = draft.endDate
        remindDaysBefore = draft.remindDaysBefore
    }
}

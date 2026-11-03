import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class EntryModel {
    public var date: LocalDate {
        didSet {
            if date != oldValue {
                billMonth = nil
            }
        }
    }

    public var walletId: Wallet.ID? {
        didSet {
            if walletId != oldValue {
                billMonth = nil
                fitCategoryToWallet()
            }
        }
    }

    public var categoryId: EntryCategory.ID? {
        didSet {
            if categoryId != oldValue {
                tagId = nil
            }
        }
    }

    public var toWalletId: Wallet.ID?
    public var memo = ""

    public private(set) var type: Entry.Kind
    public private(set) var recentMemos: [String] = []
    public private(set) var recentItemNames: [String] = []
    public private(set) var weekStart: Weekday = .sunday
    public private(set) var startsWithAmount = true

    public internal(set) var tagId: EntryTag.ID?
    public internal(set) var billMonth: YearMonth?
    public internal(set) var calculator = AmountCalculator()
    public internal(set) var feeCalculator = AmountCalculator()
    public internal(set) var items: [EntryItem.Draft] = []
    public internal(set) var taxIncluded = false
    public internal(set) var keypadTarget: KeypadTarget = .amount
    public internal(set) var options: EntryOptions?
    public internal(set) var balances: [Wallet.ID: Int] = [:]
    public internal(set) var errorNotice = ErrorNotice()
    public internal(set) var receiptSavedCount = 0

    var allTemplates: [EntryTemplate] = []
    var appliedTemplateId: EntryTemplate.ID?
    var history: EntryList?
    var isReceiptRead = false
    var receiptStore: String?

    private(set) var original: Entry?
    private(set) var categoryByType: [Entry.Kind: EntryCategory.ID] = [:]
    private(set) var cardBills: [Recurring] = []
    private(set) var budgets: [Budget] = []
    private(set) var monthStartDay: MonthStartDay = .first
    private(set) var carryoverFrom: YearMonth?
    private(set) var editingId: Entry.ID?

    let database: AppDatabase

    private var baseline: Snapshot?
    private var originalFee: Entry?
    private var isSaving = false

    private let startingTemplate: EntryTemplate?

    public init(
        database: AppDatabase,
        editing id: Entry.ID? = nil,
        date: LocalDate,
        type: Entry.Kind = .expense,
        template: EntryTemplate? = nil
    ) {
        self.database = database
        self.editingId = id
        self.date = date
        self.type = type
        self.startingTemplate = template
    }
}

public extension EntryModel {
    var isEditing: Bool {
        editingId != nil
    }

    var opensKeypad: Bool {
        startsWithAmount && !isEditing && startingTemplate == nil
    }

    var isLoaded: Bool {
        options != nil
    }

    var isChanged: Bool {
        baseline.map { $0 != snapshot } ?? false
    }

    var amount: Int {
        calculator.amount
    }

    var fee: Int {
        type == .transfer ? feeCalculator.amount : 0
    }

    var canSave: Bool {
        draft?.problems.isEmpty == true
    }

    func load() async {
        do {
            let limit = Self.recentMemoLimit
            let itemLimit = Self.recentItemNameLimit

            options = try await database.entryOptions()

            recentMemos = try await database.recentMemos(limit: limit)

            recentItemNames = try await database.recentItemNames(limit: itemLimit)

            allTemplates = try await database.templates()

            cardBills = try await database.recurrings()
                .filter { $0.type == .transfer && $0.closingDay != nil }

            weekStart = try await database.setting(.weekStart)

            monthStartDay = try await database.setting(.monthStartDay)

            carryoverFrom = try await database.setting(.budgetCarryoverFrom)

            startsWithAmount = try await database.setting(.entryStartsWithAmount)

            receiptSavedCount = try await database.setting(.receiptSavedCount)

            budgets = try await database.budgets()

            try await loadEntry()
            try await loadBalances()

            if let startingTemplate {
                apply(startingTemplate)
            }

            baseline = snapshot
        } catch {
            report(error)
        }
    }

    func select(_ type: Entry.Kind) {
        guard type != self.type else {
            return
        }

        categoryByType[self.type] = categoryId
        self.type = type
        keypadTarget = .amount

        let remembered = categoryByType[type]

        if categories.contains(where: { $0.id == remembered }) {
            categoryId = remembered
        } else if !categories.contains(where: { $0.id == categoryId }) {
            categoryId = categories.first?.id
        }

        if type == .transfer {
            chooseDestination()
        }
    }

    func save() async -> EntryChange? {
        guard
            !isSaving,
            let draft
        else {
            return nil
        }

        isSaving = true

        do {
            let saved = try await database.saveEntryResult(
                draft,
                editing: editingId,
                at: Date()
            )

            let entry = saved.entry

            await finishReceipt()

            let fee = try await database.fee(of: entry.id)
            let title = label(for: entry)

            let kind: EntryChange.Kind = if let original {
                .edited(previous: original, previousFee: originalFee)
            } else {
                .recorded
            }

            return EntryChange(
                kind: kind,
                entry: entry,
                label: title,
                fee: fee,
                clearedNoSpendDays: saved.clearedNoSpendDays
            )
        } catch {
            isSaving = false
            report(error)
            return nil
        }
    }

    func startNext() async {
        calculator = AmountCalculator()
        feeCalculator = AmountCalculator()
        keypadTarget = .amount
        memo = ""
        items = []
        taxIncluded = false
        isReceiptRead = false
        receiptStore = nil
        tagId = nil
        billMonth = nil
        appliedTemplateId = nil

        do {
            try await loadBalances()
        } catch {
            report(error)
        }

        baseline = snapshot
        isSaving = false
    }

    func delete() async -> EntryChange? {
        guard let original else {
            return nil
        }

        do {
            let deleted = try await database.deleteEntry(original.id)
            let title = label(for: original)

            return EntryChange(
                kind: .deleted,
                entry: original,
                label: title,
                fee: deleted.first { $0.transferId == original.id }
            )
        } catch {
            report(error)
            return nil
        }
    }
}

extension EntryModel {
    static var today: LocalDate {
        LocalDate(Date(), in: .current)
    }

    func report(_ error: any Error) {
        guard !(error is CancellationError) else {
            return
        }

        errorNotice.show(Self.message(for: error))
    }
}

private extension EntryModel {
    func loadEntry() async throws {
        guard let editingId else {
            categoryId = categories.first?.id
            walletId = wallets.first?.id

            if type == .transfer {
                chooseDestination()
            }

            return
        }

        guard var entry = try await database.entry(editingId) else {
            throw AppDatabase.WriteError.entryNotFound
        }

        if let transferId = entry.transferId,
           let transfer = try await database.entry(transferId) {
            entry = transfer
            self.editingId = transferId
        }

        originalFee = try await database.fee(of: entry.id)
        original = entry
        type = entry.type
        calculator = AmountCalculator(amount: entry.amount)
        date = entry.date
        categoryId = entry.categoryId
        tagId = entry.tagId
        walletId = entry.walletId
        toWalletId = entry.toWalletId
        memo = entry.memo ?? ""
        appliedTemplateId = entry.templateId
        billMonth = entry.billMonth
        feeCalculator = AmountCalculator(amount: originalFee?.amount ?? 0)
        items = try await database.entryItems(of: entry.id).map(EntryItem.Draft.init)
        taxIncluded = entry.taxIncluded
    }
}

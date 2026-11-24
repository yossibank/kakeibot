import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class EntryModel {
    public let state: State
    public let input: Input
    public let output: Output

    let dependencies: Dependencies

    public init(
        database: AppDatabase,
        clock: ScreenClock,
        editing id: Entry.ID? = nil,
        date: LocalDate,
        type: Entry.Kind = .expense,
        template: EntryTemplate? = nil
    ) {
        let state = State(type: type, date: date, today: clock.today)
        let input = Input(editingId: id, startingTemplate: template)

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = Dependencies(database: database, clock: clock)
    }
}

public extension EntryModel {
    func load() async {
        do {
            let database = dependencies.database
            let limit = Self.recentMemoLimit
            let itemLimit = Self.recentItemNameLimit

            input.options = try await database.entryOptions()

            input.recentMemos = try await database.recentMemos(limit: limit)

            input.recentItemNames = try await database.recentItemNames(limit: itemLimit)

            input.allTemplates = try await database.templates()

            input.cardBills = try await database.recurrings()
                .filter { $0.type == .transfer && $0.closingDay != nil }

            input.weekStart = try await database.setting(.weekStart)

            input.monthStartDay = try await database.setting(.monthStartDay)

            input.carryoverFrom = try await database.setting(.budgetCarryoverFrom)

            input.receiptSavedCount = try await database.setting(.receiptSavedCount)

            input.receiptGuideHidden = try await database.setting(.receiptGuideHidden)

            input.budgets = try await database.budgets()

            try await loadEntry()
            try await loadHistory()

            if !output.isEditing {
                startNew()
            }

            if let startingTemplate = input.startingTemplate {
                apply(startingTemplate)
            }

            input.baseline = output.snapshot
        } catch {
            report(error)
        }
    }

    func select(_ type: Entry.Kind) {
        guard type != state.type else {
            return
        }

        let isUntouched = !output.isEditing && !output.isChanged

        state.category.remember(for: state.type)
        state.type = type
        state.keypad.target = .amount

        if isUntouched,
           type != .transfer {
            setWallet(output.usualWalletId)
        }

        let remembered = state.category.byType[type]
        let categories = output.categories

        if categories.contains(where: { $0.id == remembered }) {
            state.setCategory(remembered)
        } else if !categories.contains(where: { $0.id == state.category.id }) {
            state.setCategory(categories.first?.id)
        }

        if type == .transfer {
            chooseDestination()
        }

        if isUntouched {
            input.baseline = output.snapshot
        }
    }

    func save() async -> EntryChange? {
        guard
            !state.isSaving,
            let draft = output.draft
        else {
            return nil
        }

        state.isSaving = true

        do {
            let database = dependencies.database

            let saved = try await database.saveEntryResult(
                draft,
                editing: input.editingId,
                at: dependencies.clock.now
            )

            let entry = saved.entry

            await finishReceipt()

            let fee = try await database.fee(of: entry.id)
            let title = output.label(for: entry)

            let kind: EntryChange.Kind = if let original = input.original {
                .edited(previous: original, previousFee: input.originalFee)
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
            state.isSaving = false
            report(error)
            return nil
        }
    }

    func startNext() async {
        state.clearForNext()

        do {
            try await loadHistory()
        } catch {
            report(error)
        }

        input.baseline = output.snapshot
        state.isSaving = false
    }

    func recordAgain() async {
        state.voiceFilled = nil
        input.editingId = nil
        input.original = nil
        input.originalFee = nil
        state.keypad.feeCalculator = AmountCalculator()
        state.appliedTemplateId = nil
        updateToday()
        state.setDate(state.today)
        state.payment.billMonth = nil
        state.items = Items()
        state.keypad.target = .amount

        if !output.wallets.contains(where: { $0.id == state.payment.walletId }) {
            setWallet(output.wallets.first?.id)
        }

        if !output.wallets.contains(where: { $0.id == state.payment.toWalletId }) {
            state.setDestination(nil)
        }

        if state.type == .transfer {
            chooseDestination()
        } else if !output.categories.contains(where: { $0.id == state.category.id }) {
            state.setCategory(output.categories.first?.id)
        }

        let tagId = state.category.tagId

        if !output.tags.contains(where: { $0.id == tagId && $0.archivedAt == nil }) {
            state.category.tagId = nil
        }

        do {
            try await loadHistory()
        } catch {
            report(error)
        }

        input.baseline = output.snapshot
        state.isSaving = false

        state.errorNotice.inform(Self.recordAgainMessage)
    }

    func delete() async -> EntryChange? {
        guard let original = input.original else {
            return nil
        }

        do {
            let deleted = try await dependencies.database.deleteEntry(
                original.id,
                at: dependencies.clock.now
            )

            let title = output.label(for: original)

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

    func newNoticeModel() -> EntryNoticeModel {
        EntryNoticeModel(database: dependencies.database, clock: dependencies.clock)
    }
}

extension EntryModel {
    struct Dependencies {
        let database: AppDatabase
        let clock: ScreenClock
    }

    public func newVoiceFlow() -> EntryVoiceFlow {
        EntryVoiceFlow(dependencies: .live(clock: dependencies.clock))
    }

    func report(_ error: any Error) {
        guard !(error is CancellationError) else {
            return
        }

        state.errorNotice.show(Self.message(for: error))
    }
}

private extension EntryModel {
    static let recordAgainMessage = "同じ内容で新しい記録にしました"

    func startNew() {
        state.setCategory(output.categories.first?.id)
        setWallet(output.usualWalletId)

        if state.type == .transfer {
            chooseDestination()
        }
    }

    func loadEntry() async throws {
        guard let editingId = input.editingId else {
            return
        }

        let database = dependencies.database

        guard var entry = try await database.entry(editingId) else {
            throw AppDatabase.EntryWriteError.entryNotFound
        }

        if let transferId = entry.transferId,
           let transfer = try await database.entry(transferId) {
            entry = transfer
            input.editingId = transferId
        }

        input.originalFee = try await database.fee(of: entry.id)
        input.original = entry
        state.type = entry.type
        state.keypad.setAmount(entry.amount)
        state.setDate(entry.date)
        state.setCategory(entry.categoryId)
        state.category.tagId = entry.tagId
        setWallet(entry.walletId)
        state.setDestination(entry.toWalletId)
        state.memo = entry.memo ?? ""
        state.appliedTemplateId = entry.templateId
        state.payment.billMonth = entry.billMonth
        state.keypad.setFee(input.originalFee?.amount ?? 0)
        state.items.list = try await database.entryItems(of: entry.id).map(EntryItem.Draft.init)
        state.items.taxIncluded = entry.taxIncluded
    }
}

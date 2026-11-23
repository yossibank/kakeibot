import Core
import DesignSystem
import Foundation
import Store

public extension RecurringEditModel {
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
}

extension RecurringEditModel {
    static let billClosingDay = 31
    static let billPaymentDay = 27
    static let loadFailedMessage = "固定費を読めませんでした"

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
        repayment.manualFinal = recurring.finalAmount
        repayment.generatedUntil = recurring.generatedUntil
        billShift = draft.billShift
        startDate = draft.startDate
        endDate = draft.endDate
        remindDaysBefore = draft.remindDaysBefore
    }
}

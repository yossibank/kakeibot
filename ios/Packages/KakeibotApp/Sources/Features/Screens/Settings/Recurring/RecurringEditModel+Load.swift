import Core
import DesignSystem
import Store

public extension RecurringEditModel {
    func load() async {
        do {
            input.options = try await dependencies.database.entryOptions()
            input.cardBills = try await dependencies.database.recurrings()

            try await loadLoanBalances()
            try await loadRecurring()
            presetPayment()

            if state.categoryId == nil {
                state.categoryId = output.categories.first?.id
            }

            suggestHolidayShift()

            if state.walletId == nil {
                state.setWallet(output.wallets.first?.id)
            }

            presetDestination()
            chooseCountMode()
            input.baseline = output.draft
        } catch is CancellationError {
            return
        } catch {
            state.errorNotice.show(Self.loadFailedMessage)
        }
    }
}

extension RecurringEditModel {
    static let billClosingDay = 31
    static let billPaymentDay = 27
    static let loadFailedMessage = "固定費を読めませんでした"

    func presetPayment() {
        guard
            !output.isEditing,
            let target = input.paidWallet
        else {
            return
        }

        let wallets = output.wallets
        let bank = wallets.first { $0.kind == .bank && $0.id != target }
        let other = wallets.first { $0.id != target }

        state.type = .transfer
        state.categoryId = nil
        state.toWalletId = target
        state.setWallet((bank ?? other)?.id)
        state.schedule.day = Self.billPaymentDay

        let destination = output.selectedDestination
        let name = destination?.name ?? ""

        if destination?.kind == .card {
            state.schedule.closingDay = Self.billClosingDay
            state.memo = name
        } else {
            state.memo = "\(name)の返済"
        }
    }

    func presetDestination() {
        guard
            state.type == .transfer,
            state.toWalletId == nil
        else {
            return
        }

        state.toWalletId = output.wallets.first { $0.id != state.walletId }?.id
    }

    func suggestHolidayShift() {
        guard
            !output.isEditing,
            !state.schedule.isHolidayShiftChosen
        else {
            return
        }

        state.schedule.holidayShift = output.suggestedHolidayShift
    }

    func loadRecurring() async throws {
        guard let editingId = input.editingId else {
            return
        }

        let recurrings = try await dependencies.database.recurrings(includingHidden: true)
        let recurring = recurrings.first { $0.id == editingId }

        guard let recurring else {
            throw AppDatabase.RecurringWriteError.recurringNotFound
        }

        input.isHidden = recurring.archivedAt != nil
        input.generatedUntil = recurring.generatedUntil

        state.apply(RecurringDraft(recurring))
        state.repayment.manualFinal = recurring.finalAmount
    }
}

import Core
import DesignSystem
import Store

public extension RecurringEditModel {
    @MainActor
    final class Output {
        let input: Input
        let state: State

        init(
            input: Input,
            state: State
        ) {
            self.input = input
            self.state = state
        }
    }
}

public extension RecurringEditModel.Output {
    var amount: Int {
        state.calculators.amount.amount
    }

    var walletTitle: String {
        state.type.walletTitle
    }

    var draft: RecurringDraft {
        let schedule = state.fields.schedule
        let closing = canUseClosingDay ? schedule.closingDay : nil
        let transferFee = state.type == .transfer ? fee : 0

        return RecurringDraft(
            type: state.type,
            amount: amount,
            categoryId: state.categoryId,
            walletId: state.walletId,
            toWalletId: state.toWalletId,
            memo: state.fields.memo,
            frequency: schedule.frequency,
            month: schedule.month,
            day: schedule.day,
            holidayShift: schedule.holidayShift,
            closingDay: closing,
            fee: transferFee,
            finalAmount: finalAmount ?? 0,
            billShift: billRecurring == nil ? 0 : state.fields.billShift,
            startDate: schedule.startDate,
            endDate: scheduledEndDate,
            remindDaysBefore: schedule.remindDaysBefore
        )
    }

    var billRecurring: Recurring? {
        state.type == .transfer ? nil : input.cardBills.cardBill(paidBy: state.walletId)
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
        state.type == .transfer && selectedDestination?.kind == .card
    }

    var fee: Int {
        state.calculators.fee.amount
    }

    var isCardBill: Bool {
        canUseClosingDay && state.fields.schedule.closingDay != nil
    }

    var isLoanRepayment: Bool {
        state.type == .transfer && selectedDestination?.kind == .loan
    }

    var isNotificationDenied: Bool {
        state.fields.schedule.remindDaysBefore != nil && input.authorization == .denied
    }

    var categories: [EntryCategory] {
        input.options?.categories(of: state.type) ?? []
    }

    var wallets: [Wallet] {
        input.options?.wallets ?? []
    }

    var selectedCategory: EntryCategory? {
        categories.first { $0.id == state.categoryId }
    }

    var selectedWallet: Wallet? {
        wallets.first { $0.id == state.walletId }
    }

    var selectedDestination: Wallet? {
        wallets.first { $0.id == state.toWalletId }
    }

    func icon(for category: EntryCategory) -> Icon? {
        input.options?.icon(for: category)
    }

    func icon(for wallet: Wallet) -> Icon? {
        input.options?.icon(for: wallet)
    }
}

extension RecurringEditModel.Output {
    var isEditing: Bool {
        input.editingId != nil
    }

    var problemMessage: String? {
        draft.problems.first.map(message)
    }

    var suggestedHolidayShift: HolidayShift {
        guard state.type != .transfer else {
            return .next
        }

        let glyph = selectedCategory.flatMap { icon(for: $0) }?.glyph

        switch glyph {
        case .salary, .bonus: return .previous
        case .home, .utility, .phone: return .next
        default: return .none
        }
    }
}

private extension RecurringEditModel.Output {
    func message(for problem: RecurringDraft.Problem) -> String {
        switch problem {
        case .amountNotPositive: "金額を入れてください"
        case .missingCategory: "カテゴリを選んでください"
        case .missingWallet: "\(walletTitle)を選んでください"
        case .missingDestination: "\(RecurringEditModel.destinationTitle)を選んでください"
        case .sameWallet: "振替元と振替先を別にしてください"
        case .endBeforeStart: "終わりを始まりより後にしてください"
        case .categoryOnTransfer, .dayOutOfRange, .closingDayOutOfRange,
             .monthOutOfRange, .remindOutOfRange, .feeNegative:
            SettingsEditMessage.saveFailed
        }
    }
}

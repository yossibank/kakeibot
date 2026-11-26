import Core
import DesignSystem
import Foundation
import Store

public extension RecurringEditModel.Output {
    var previewRow: RecurringListModel.Row {
        let schedule = state.schedule
        let type = state.type

        let text = RecurringText.schedule(
            schedule.frequency,
            month: schedule.month,
            day: schedule.day
        )

        let holiday = RecurringText.holidayNote(schedule.holidayShift)
        let detail = [text, holiday].rowDetail ?? text
        let closing = canUseClosingDay ? schedule.closingDay.map(RecurringText.closingNote) : nil
        let name = state.fields.memo.trimmingCharacters(in: .whitespaces)
        let destination = type == .transfer ? selectedDestination?.name : nil
        let place = [selectedWallet?.name, destination].compactMap(\.self).joined(separator: " → ")
        let rowPlace = place.isEmpty ? nil : place
        let wallet = state.walletId ?? Wallet.ID()
        let rowAmount = isCardBill ? nil : amount

        let title = name.isEmpty
            ? selectedCategory?.name ?? RecurringListModel.title(of: type)
            : name

        let icon = type == .transfer
            ? selectedWallet.flatMap(icon(for:))
            : selectedCategory.flatMap(icon(for:))

        let recurring = Recurring(
            type: type,
            amount: amount,
            categoryId: state.categoryId,
            walletId: wallet,
            frequency: schedule.frequency,
            month: schedule.month,
            day: schedule.day,
            holidayShift: schedule.holidayShift,
            startDate: schedule.startDate,
            endDate: scheduledEndDate,
            createdAt: .distantPast,
            updatedAt: .distantPast
        )

        let next = recurring.nextDate(onOrAfter: input.today)

        return RecurringListModel.Row(
            id: recurring.id,
            title: title,
            schedule: detail,
            place: rowPlace,
            amount: rowAmount,
            type: type,
            icon: icon,
            next: next,
            closing: closing
        )
    }
}

import Core
import DesignSystem
import Foundation
import Store

public extension RecurringEditModel {
    var previewRow: RecurringListModel.Row {
        let schedule = RecurringText.schedule(frequency, month: month, day: day)
        let holiday = RecurringText.holidayNote(holidayShift)
        let detail = [schedule, holiday].rowDetail ?? schedule
        let closing = canUseClosingDay ? closingDay.map(RecurringText.closingNote) : nil
        let name = memo.trimmingCharacters(in: .whitespaces)
        let destination = type == .transfer ? selectedDestination?.name : nil
        let place = [selectedWallet?.name, destination].compactMap(\.self).joined(separator: " → ")
        let rowPlace = place.isEmpty ? nil : place
        let wallet = walletId ?? Wallet.ID()
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
            categoryId: categoryId,
            walletId: wallet,
            frequency: frequency,
            month: month,
            day: day,
            holidayShift: holidayShift,
            startDate: startDate,
            endDate: scheduledEndDate,
            createdAt: Date(),
            updatedAt: Date()
        )

        let next = recurring.nextDate(onOrAfter: today)

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

package com.yossibank.kakeibot.features.screens.settings.recurrings

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.recurring.nextDate
import com.yossibank.kakeibot.core.shared.Identifier

val RecurringEditModel.previewRow: RecurringRow
    get() {
        val isTransfer = form.type == Entry.Kind.transfer

        val schedule = RecurringText.schedule(
            frequency = form.frequency,
            month = form.month,
            day = form.day,
        )

        val name = form.memo.trim()
        val destination = if (isTransfer) selectedDestination?.name else null
        val place = listOfNotNull(selectedWallet?.name, destination).joinToString(" → ")

        val icon = if (isTransfer) {
            selectedWallet?.let { icon(it.iconId) }
        } else {
            selectedCategory?.let { icon(it.iconId) }
        }

        val next = recurring(
            endDate = scheduledEndDate,
            finalAmount = null,
        ).nextDate(onOrAfter = today)

        val closing = if (canUseClosingDay) {
            form.closingDay?.let(RecurringText::closingNote)
        } else {
            null
        }

        return RecurringRow(
            id = editingId ?: Identifier(),
            title = name.ifEmpty { selectedCategory?.name ?: RecurringListModel.title(form.type) },
            schedule = RecurringText.detail(
                schedule = schedule,
                holiday = RecurringText.holidayNote(form.holidayShift),
            ),
            place = place.ifEmpty { null },
            amount = if (isCardBill) null else amount,
            type = form.type,
            icon = icon,
            next = next,
            closing = closing,
        )
    }

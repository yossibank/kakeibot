package com.yossibank.kakeibot.featuremodels.screens.settings.recurring

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.recurring.nextDate
import com.yossibank.kakeibot.core.shared.Identifier

val RecurringEditModel.Output.previewRow: RecurringRow
    get() {
        val isTransfer = state.form.type == Entry.Kind.transfer

        val schedule = RecurringText.schedule(
            frequency = state.form.frequency,
            month = state.form.month,
            day = state.form.day,
        )

        val name = state.form.memo.trim()
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
        ).nextDate(onOrAfter = state.today)

        val closing = if (canUseClosingDay) {
            state.form.closingDay?.let(RecurringText::closingNote)
        } else {
            null
        }

        return RecurringRow(
            id = input.editingId ?: Identifier(),
            title = name.ifEmpty {
                selectedCategory?.name
                    ?: RecurringListModel.title(state.form.type)
            },
            schedule = RecurringText.detail(
                schedule = schedule,
                holiday = RecurringText.holidayNote(state.form.holidayShift),
            ),
            place = place.ifEmpty { null },
            amount = if (isCardBill) null else amount,
            type = state.form.type,
            icon = icon,
            next = next,
            closing = closing,
        )
    }

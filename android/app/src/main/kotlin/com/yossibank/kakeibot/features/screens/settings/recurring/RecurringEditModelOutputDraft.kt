package com.yossibank.kakeibot.features.screens.settings.recurring

import com.yossibank.kakeibot.core.concepts.date.HolidayShift
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.RecurringDraft
import com.yossibank.kakeibot.core.shared.Identifier
import java.time.Instant

val RecurringEditModel.Output.draft: RecurringDraft
    get() {
        val form = state.form

        return RecurringDraft(
            type = form.type,
            amount = amount,
            categoryId = form.categoryId,
            walletId = form.walletId,
            toWalletId = form.toWalletId,
            memo = form.memo,
            frequency = form.frequency,
            month = form.month,
            day = form.day,
            holidayShift = form.holidayShift,
            closingDay = if (canUseClosingDay) form.closingDay else null,
            fee = if (form.type == Entry.Kind.transfer) fee else 0,
            finalAmount = finalAmount ?: 0,
            billShift = if (billRecurring == null) 0 else form.billShift,
            startDate = form.startDate,
            endDate = scheduledEndDate,
            remindDaysBefore = form.remindDaysBefore,
        )
    }

val RecurringEditModel.Output.canSave: Boolean
    get() = draft.problems.isEmpty()

val RecurringEditModel.Output.saveTitle: String
    get() {
        val problem =
            draft.problems.firstOrNull() ?: return if (isEditing) "変更を保存" else "追加する"
        return message(problem)
    }

val RecurringEditModel.Output.isChanged: Boolean
    get() = input.baseline?.let { it != draft } ?: false

val RecurringEditModel.Output.suggestedHolidayShift: HolidayShift
    get() {
        if (state.form.type == Entry.Kind.transfer) {
            return HolidayShift.next
        }

        val glyph = selectedCategory?.let { icon(it.iconId) }?.glyph

        return when (glyph) {
            Icon.Glyph.salary, Icon.Glyph.bonus -> HolidayShift.previous
            Icon.Glyph.home, Icon.Glyph.utility, Icon.Glyph.phone -> HolidayShift.next
            else -> HolidayShift.none
        }
    }

fun RecurringEditModel.Output.recurring(
    endDate: LocalDate?,
    finalAmount: Int?,
): Recurring {
    val form = state.form

    return Recurring(
        type = form.type,
        amount = amount,
        categoryId = null,
        walletId = form.walletId ?: Identifier(),
        toWalletId = form.toWalletId,
        frequency = form.frequency,
        month = if (form.frequency == Recurring.Frequency.yearly) form.month else null,
        day = form.day,
        holidayShift = form.holidayShift,
        finalAmount = finalAmount,
        startDate = form.startDate,
        endDate = endDate,
        createdAt = Instant.EPOCH,
        updatedAt = Instant.EPOCH,
    )
}

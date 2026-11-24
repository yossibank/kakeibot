package com.yossibank.kakeibot.features.screens.settings.recurring

import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.date.HolidayShift
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.features.shared.period.title

data class RecurringDetailRow(
    val panel: RecurringPanel,
    val icon: Int,
    val value: String,
    val isEmpty: Boolean,
)

val RecurringEditModel.Output.detailRows: List<RecurringDetailRow>
    get() = transferRows + scheduleRows

private val RecurringEditModel.Output.transferRows: List<RecurringDetailRow>
    get() {
        if (state.form.type != Entry.Kind.transfer) {
            return emptyList()
        }

        val feeRow = RecurringDetailRow(
            panel = RecurringPanel.Fee,
            icon = R.drawable.ic_bank,
            value = if (fee > 0) AmountText.text(amount = fee) else "なし",
            isEmpty = fee == 0,
        )

        return listOfNotNull(countRow ?: closingRow, feeRow)
    }

private val RecurringEditModel.Output.countRow: RecurringDetailRow?
    get() {
        if (!isLoanRepayment) {
            return null
        }

        val count = repaymentCount

        val value = when {
            count == null -> "決めない"
            usesAutoCount -> "自動 · $count 回"
            else -> "$count 回"
        }

        return RecurringDetailRow(
            panel = RecurringPanel.Count,
            icon = R.drawable.ic_repeat,
            value = value,
            isEmpty = count == null,
        )
    }

private val RecurringEditModel.Output.closingRow: RecurringDetailRow?
    get() {
        if (!canUseClosingDay) {
            return null
        }

        return RecurringDetailRow(
            panel = RecurringPanel.Closing,
            icon = R.drawable.ic_card,
            value = RecurringText.closingDay(state.form.closingDay),
            isEmpty = state.form.closingDay == null,
        )
    }

private val RecurringEditModel.Output.scheduleRows: List<RecurringDetailRow>
    get() {
        val end = scheduledEndDate

        return listOf(
            RecurringDetailRow(
                panel = RecurringPanel.Start,
                icon = R.drawable.ic_calendar,
                value = RecurringText.date(state.form.startDate),
                isEmpty = false,
            ),
            RecurringDetailRow(
                panel = RecurringPanel.End,
                icon = R.drawable.ic_calendar,
                value = end?.let(RecurringText::date) ?: "なし",
                isEmpty = end == null,
            ),
            RecurringDetailRow(
                panel = RecurringPanel.Holiday,
                icon = R.drawable.ic_calendar,
                value = state.form.holidayShift.title,
                isEmpty = state.form.holidayShift == HolidayShift.none,
            ),
            RecurringDetailRow(
                panel = RecurringPanel.Remind,
                icon = R.drawable.ic_bell,
                value = RecurringText.remind(state.form.remindDaysBefore),
                isEmpty = state.form.remindDaysBefore == null,
            ),
        )
    }

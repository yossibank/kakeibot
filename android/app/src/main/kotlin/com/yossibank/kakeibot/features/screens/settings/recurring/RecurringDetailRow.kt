package com.yossibank.kakeibot.features.screens.settings.recurring

import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.date.HolidayShift
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.RecurringEditModel
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.RecurringPanel
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.RecurringText
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.canUseClosingDay
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.isLoanRepayment
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.repaymentCount
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.scheduledEndDate
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.usesAutoCount
import com.yossibank.kakeibot.featuremodels.shared.amount.AmountText
import com.yossibank.kakeibot.featuremodels.shared.period.title

data class RecurringDetailRow(
    val panel: RecurringPanel,
    val icon: Int,
    val value: String,
    val isEmpty: Boolean,
)

val RecurringEditModel.detailRows: List<RecurringDetailRow>
    get() = transferRows + scheduleRows

private val RecurringEditModel.transferRows: List<RecurringDetailRow>
    get() {
        if (state.fields.form.type != Entry.Kind.transfer) {
            return emptyList()
        }

        val feeRow = RecurringDetailRow(
            panel = RecurringPanel.Fee,
            icon = R.drawable.ic_bank,
            value = if (output.fee > 0) AmountText.text(amount = output.fee) else "なし",
            isEmpty = output.fee == 0,
        )

        return listOfNotNull(countRow ?: closingRow, feeRow)
    }

private val RecurringEditModel.countRow: RecurringDetailRow?
    get() {
        if (!output.isLoanRepayment) {
            return null
        }

        val count = output.repaymentCount

        val value = when {
            count == null -> "決めない"
            output.usesAutoCount -> "自動 · $count 回"
            else -> "$count 回"
        }

        return RecurringDetailRow(
            panel = RecurringPanel.Count,
            icon = R.drawable.ic_repeat,
            value = value,
            isEmpty = count == null,
        )
    }

private val RecurringEditModel.closingRow: RecurringDetailRow?
    get() {
        if (!output.canUseClosingDay) {
            return null
        }

        return RecurringDetailRow(
            panel = RecurringPanel.Closing,
            icon = R.drawable.ic_card,
            value = RecurringText.closingDay(state.fields.form.closingDay),
            isEmpty = state.fields.form.closingDay == null,
        )
    }

private val RecurringEditModel.scheduleRows: List<RecurringDetailRow>
    get() {
        val end = output.scheduledEndDate

        return listOf(
            RecurringDetailRow(
                panel = RecurringPanel.Start,
                icon = R.drawable.ic_calendar,
                value = RecurringText.date(state.fields.form.startDate),
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
                value = state.fields.form.holidayShift.title,
                isEmpty = state.fields.form.holidayShift == HolidayShift.none,
            ),
            RecurringDetailRow(
                panel = RecurringPanel.Remind,
                icon = R.drawable.ic_bell,
                value = RecurringText.remind(state.fields.form.remindDaysBefore),
                isEmpty = state.fields.form.remindDaysBefore == null,
            ),
        )
    }

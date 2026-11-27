package com.yossibank.kakeibot.features.screens.settings.recurring

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.core.concepts.date.HolidayShift
import com.yossibank.kakeibot.designsystem.components.date.MonthCalendar
import com.yossibank.kakeibot.designsystem.components.input.Keypad
import com.yossibank.kakeibot.designsystem.components.row.FeeChoiceRow
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.RecurringEditModel
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.RecurringPanel
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.RecurringText
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.autoPlan
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.countCalculator
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.loanOwed
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.prepareCount
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.pressCount
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.scheduledEndDate
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.setEnd
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.usesAutoCount
import com.yossibank.kakeibot.featuremodels.shared.amount.AmountText
import com.yossibank.kakeibot.featuremodels.shared.amount.FeeChoiceRow
import com.yossibank.kakeibot.featuremodels.shared.period.title
import com.yossibank.kakeibot.features.shared.settingsparts.input.ChoiceChip

@Composable
fun RecurringPanelBody(
    panel: RecurringPanel,
    model: RecurringEditModel,
    onClose: () -> Unit,
) {
    when (panel) {
        RecurringPanel.Amount -> AmountKeypad(model = model)

        RecurringPanel.Start -> MonthCalendar(
            selection = model.state.form.startDate,
            today = model.input.today,
            onSelect = { date ->
                model.state.update { copy(startDate = date) }
                onClose()
            },
        )

        RecurringPanel.End -> EndChooser(
            model = model,
            onClose = onClose,
        )

        RecurringPanel.Holiday -> HolidayChooser(
            model = model,
            onClose = onClose,
        )

        RecurringPanel.Closing -> ClosingChooser(
            model = model,
            onClose = onClose,
        )

        RecurringPanel.Fee -> FeeKeypad(model = model)

        RecurringPanel.Count -> CountKeypad(
            model = model,
            onClose = onClose,
        )

        RecurringPanel.Remind -> RemindChoices(
            model = model,
            onClose = onClose,
        )
    }
}

@Composable
private fun AmountKeypad(model: RecurringEditModel) {
    Column(
        verticalArrangement = Arrangement.spacedBy(12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        KeypadValue(amount = model.output.amount)

        Keypad(
            calculator = model.state.calculator,
            onKey = model.state::press,
        )
    }
}

@Composable
private fun EndChooser(
    model: RecurringEditModel,
    onClose: () -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            ChoiceChip(
                title = "終わりなし",
                isSelected = model.output.scheduledEndDate == null,
                onSelect = {
                    model.setEnd(null)
                    onClose()
                },
            )

            ChoiceChip(
                title = "今日で終える",
                isSelected = model.output.scheduledEndDate == model.input.today,
                onSelect = {
                    model.setEnd(model.input.today)
                    onClose()
                },
            )
        }

        MonthCalendar(
            selection = model.output.scheduledEndDate ?: model.state.form.startDate,
            today = model.input.today,
            onSelect = {
                model.setEnd(it)
                onClose()
            },
        )
    }
}

@Composable
private fun HolidayChooser(
    model: RecurringEditModel,
    onClose: () -> Unit,
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Note(text = "土日・祝日・年末年始（12/31〜1/3）に当たったときに、日をずらします")

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            HolidayShift.entries.forEach { shift ->
                ChoiceChip(
                    title = shift.title,
                    isSelected = model.state.form.holidayShift == shift,
                    onSelect = {
                        model.state.choose(shift)
                        onClose()
                    },
                )
            }
        }
    }
}

@Composable
private fun ClosingChooser(
    model: RecurringEditModel,
    onClose: () -> Unit,
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Note(text = "締め日までのカードの利用分を、引き落とし日に振り替えます")

        ChoiceChip(
            title = RecurringText.closingDay(null),
            isSelected = model.state.form.closingDay == null,
            onSelect = {
                model.state.update { copy(closingDay = null) }
                onClose()
            },
        )

        DayGrid(
            selection = model.state.form.closingDay,
            onSelect = { day ->
                model.state.update { copy(closingDay = day) }
                onClose()
            },
        )
    }
}

@Composable
private fun FeeKeypad(model: RecurringEditModel) {
    Column(
        verticalArrangement = Arrangement.spacedBy(12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        KeypadValue(amount = model.output.fee)

        FeeChoiceRow(
            choices = FeeChoiceRow.defaultChoices,
            selection = model.output.fee,
            onSelect = model.state::setFee,
        )

        Keypad(
            calculator = model.state.feeCalculator,
            onKey = model.state::pressFee,
        )
    }
}

@Composable
private fun CountKeypad(
    model: RecurringEditModel,
    onClose: () -> Unit,
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        CountChoices(
            model = model,
            onClose = onClose,
        )

        Text(
            text = "${model.output.countCalculator.amount} 回",
            color = Palette.accentStrong,
            style = displayFont(
                size = FontSize.LargeTitle,
                weight = FontWeight.Bold,
            ),
        )

        Note(
            text = model.output.scheduledEndDate?.let { "終わり ${RecurringText.date(it)}" }
                ?: "回数を入れると、終わりの日が決まります",
        )

        Keypad(
            calculator = model.output.countCalculator,
            onKey = model::pressCount,
        )
    }
}

@Composable
private fun CountChoices(
    model: RecurringEditModel,
    onClose: () -> Unit,
) {
    val plan = model.output.autoPlan ?: return
    val owed = model.output.loanOwed ?: return

    Column(
        verticalArrangement = Arrangement.spacedBy(8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            ChoiceChip(
                title = "残高から自動",
                isSelected = model.output.usesAutoCount,
                onSelect = {
                    model.state.useAutoCount()
                    model.prepareCount()
                },
            )

            ChoiceChip(
                title = "決めない",
                isSelected = model.output.scheduledEndDate == null,
                onSelect = {
                    model.setEnd(null)
                    onClose()
                },
            )
        }

        Note(
            text =
                "残高 ${AmountText.text(
                    amount = owed,
                )} ÷ ${AmountText.text(amount = model.output.amount)} で " +
                    "${plan.count} 回。端数は最後の回に足します",
        )
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun RemindChoices(
    model: RecurringEditModel,
    onClose: () -> Unit,
) {
    FlowRow(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        RecurringEditModel.remindChoices.forEach { days ->
            ChoiceChip(
                title = RecurringText.remind(days),
                isSelected = model.state.form.remindDaysBefore == days,
                onSelect = {
                    model.state.update { copy(remindDaysBefore = days) }
                    onClose()
                },
                modifier = Modifier.widthIn(min = 96.dp),
            )
        }
    }
}

@Composable
private fun KeypadValue(amount: Int) {
    AmountText(
        amount = amount,
        style = displayFont(
            size = FontSize.LargeTitle,
            weight = FontWeight.Bold,
        ),
        color = Palette.accentStrong,
    )
}

@Composable
private fun Note(text: String) {
    Text(
        text = text,
        color = Palette.subtext,
        textAlign = TextAlign.Center,
        style = textFont(style = FontTextStyle.Caption),
    )
}

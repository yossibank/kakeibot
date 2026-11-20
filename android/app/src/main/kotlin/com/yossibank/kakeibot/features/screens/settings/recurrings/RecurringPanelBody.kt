package com.yossibank.kakeibot.features.screens.settings.recurrings

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
import com.yossibank.kakeibot.features.shared.period.title
import com.yossibank.kakeibot.features.shared.settingsparts.ChoiceChip

@Composable
fun RecurringPanelBody(
    panel: RecurringPanel,
    model: RecurringEditModel,
    onClose: () -> Unit,
) {
    when (panel) {
        RecurringPanel.Amount -> {
            Column(
                verticalArrangement = Arrangement.spacedBy(12.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                KeypadValue(amount = model.amount)

                Keypad(
                    calculator = model.calculator,
                    onKey = model::press,
                )
            }
        }

        RecurringPanel.Start -> {
            MonthCalendar(
                selection = model.startDate,
                today = model.today,
                onSelect = {
                    model.startDate = it
                    onClose()
                },
            )
        }

        RecurringPanel.End -> {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    ChoiceChip(
                        title = "終わりなし",
                        isSelected = model.scheduledEndDate == null,
                        onSelect = {
                            model.setEnd(null)
                            onClose()
                        },
                    )

                    ChoiceChip(
                        title = "今日で終える",
                        isSelected = model.scheduledEndDate == model.today,
                        onSelect = {
                            model.setEnd(model.today)
                            onClose()
                        },
                    )
                }

                MonthCalendar(
                    selection = model.scheduledEndDate ?: model.startDate,
                    today = model.today,
                    onSelect = {
                        model.setEnd(it)
                        onClose()
                    },
                )
            }
        }

        RecurringPanel.Holiday -> {
            Column(
                verticalArrangement = Arrangement.spacedBy(12.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Note(text = "土日・祝日・年末年始（12/31〜1/3）に当たったときに、日をずらします")

                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    HolidayShift.entries.forEach { shift ->
                        ChoiceChip(
                            title = shift.title,
                            isSelected = model.holidayShift == shift,
                            onSelect = {
                                model.choose(shift)
                                onClose()
                            },
                        )
                    }
                }
            }
        }

        RecurringPanel.Closing -> {
            Column(
                verticalArrangement = Arrangement.spacedBy(12.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Note(text = "締め日までのカードの利用分を、引き落とし日に振り替えます")

                ChoiceChip(
                    title = RecurringText.closingDay(null),
                    isSelected = model.closingDay == null,
                    onSelect = {
                        model.closingDay = null
                        onClose()
                    },
                )

                DayGrid(
                    selection = model.closingDay,
                    onSelect = {
                        model.closingDay = it
                        onClose()
                    },
                )
            }
        }

        RecurringPanel.Fee -> {
            Column(
                verticalArrangement = Arrangement.spacedBy(12.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                KeypadValue(amount = model.fee)

                FeeChoiceRow(
                    choices = FeeChoiceRow.defaultChoices,
                    selection = model.fee,
                    onSelect = model::setFee,
                )

                Keypad(
                    calculator = model.feeCalculator,
                    onKey = model::pressFee,
                )
            }
        }

        RecurringPanel.Count -> {
            Column(
                verticalArrangement = Arrangement.spacedBy(12.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                CountChoices(
                    model = model,
                    onClose = onClose,
                )

                Text(
                    text = "${model.countCalculator.amount} 回",
                    color = Palette.accentStrong,
                    style = displayFont(
                        size = FontSize.LargeTitle,
                        weight = FontWeight.Bold,
                    ),
                )

                Note(
                    text = model.scheduledEndDate?.let { "終わり ${RecurringText.date(it)}" }
                        ?: "回数を入れると、終わりの日が決まります",
                )

                Keypad(
                    calculator = model.countCalculator,
                    onKey = model::pressCount,
                )
            }
        }

        RecurringPanel.Remind -> {
            RemindChoices(
                model = model,
                onClose = onClose,
            )
        }
    }
}

@Composable
private fun CountChoices(
    model: RecurringEditModel,
    onClose: () -> Unit,
) {
    val plan = model.autoPlan ?: return
    val owed = model.loanOwed ?: return

    Column(
        verticalArrangement = Arrangement.spacedBy(8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            ChoiceChip(
                title = "残高から自動",
                isSelected = model.usesAutoCount,
                onSelect = {
                    model.useAutoCount()
                    model.prepareCount()
                },
            )

            ChoiceChip(
                title = "決めない",
                isSelected = model.scheduledEndDate == null,
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
                )} ÷ ${AmountText.text(amount = model.amount)} で " +
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
                isSelected = model.remindDaysBefore == days,
                onSelect = {
                    model.remindDaysBefore = days
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

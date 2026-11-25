package com.yossibank.kakeibot.features.screens.tabs.records.view

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryDay
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.designsystem.components.surface.Hairline
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.screens.tabs.records.model.RecordsModel
import com.yossibank.kakeibot.featuremodels.shared.amount.AmountText
import com.yossibank.kakeibot.featuremodels.shared.datechoice.shortName
import com.yossibank.kakeibot.featuremodels.shared.period.PeriodText
import com.yossibank.kakeibot.features.shared.entrylist.EntryItemRow

@Composable
internal fun RecordsDayCard(
    day: EntryDay,
    model: RecordsModel,
    onOpenEntry: (Identifier<Entry>) -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .card()
            .padding(horizontal = 16.dp)
            .padding(bottom = 4.dp),
    ) {
        DayHeader(
            day = day,
            today = model.state.today,
        )

        if (day.entries.isEmpty()) {
            Text(
                text = "この日の記録はありません",
                modifier = Modifier.padding(
                    top = 4.dp,
                    bottom = 16.dp,
                ),
                color = Palette.subtext,
                style = textFont(style = FontTextStyle.Subheadline),
            )
        }

        model.output.rows(of = day).forEach { row ->
            Hairline()

            EntryItemRow(
                item = row,
                onOpen = { onOpenEntry(row.id) },
            )
        }
    }
}

@Composable
private fun DayHeader(
    day: EntryDay,
    today: LocalDate,
) {
    val date = day.date

    val weekdayColor = weekdayColor(weekday = date.weekday)

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(
                top = 12.dp,
                bottom = 8.dp,
            ),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = PeriodText.day(
                date = date,
                today = today,
            ),
            modifier = Modifier.alignByBaseline(),
            color = Palette.accentStrong,
            style = displayFont(style = FontTextStyle.Title3),
        )

        Text(
            text = "（${date.weekday.shortName}）",
            modifier = Modifier.alignByBaseline(),
            color = weekdayColor,
            style = textFont(style = FontTextStyle.Caption),
        )

        if (date == today) {
            Text(
                text = "今日",
                modifier = Modifier.alignByBaseline(),
                color = Palette.accent,
                style = textFont(
                    style = FontTextStyle.Caption2,
                    weight = FontWeight.SemiBold,
                ),
            )
        }

        Spacer(modifier = Modifier.weight(1f))

        if (day.expenseTotal > 0) {
            AmountText(
                amount = day.expenseTotal.toInt(),
                style = displayFont(style = FontTextStyle.Footnote),
                modifier = Modifier.alignByBaseline(),
                type = Entry.Kind.expense,
            )
        }

        if (day.incomeTotal > 0) {
            AmountText(
                amount = day.incomeTotal.toInt(),
                style = displayFont(style = FontTextStyle.Footnote),
                modifier = Modifier.alignByBaseline(),
                type = Entry.Kind.income,
            )
        }
    }
}

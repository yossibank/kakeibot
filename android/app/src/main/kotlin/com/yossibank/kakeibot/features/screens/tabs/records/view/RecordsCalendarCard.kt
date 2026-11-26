package com.yossibank.kakeibot.features.screens.tabs.records.view

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.date.Holiday
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.Weekday
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryDay
import com.yossibank.kakeibot.core.concepts.setting.RecordsLayout
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.designsystem.components.entry.EntryRow
import com.yossibank.kakeibot.designsystem.components.input.SegmentSwitch
import com.yossibank.kakeibot.designsystem.components.surface.Hairline
import com.yossibank.kakeibot.designsystem.components.surface.VerticalRule
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.screens.tabs.records.model.RecordsModel
import com.yossibank.kakeibot.featuremodels.shared.datechoice.shortName
import com.yossibank.kakeibot.features.shared.entrylist.EntryItemRow
import com.yossibank.kakeibot.features.shared.period.PeriodStepper
import kotlinx.coroutines.launch

@Composable
internal fun RecordsCalendarCard(model: RecordsModel) {
    val selected = model.output.selectedDate

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .card()
            .padding(
                horizontal = 8.dp,
                vertical = 12.dp,
            ),
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Row(modifier = Modifier.fillMaxWidth()) {
            model.output.weekdays.forEach { weekday ->
                Text(
                    text = weekday.shortName,
                    modifier = Modifier.weight(1f),
                    color = weekdayColor(weekday = weekday),
                    textAlign = TextAlign.Center,
                    style = textFont(style = FontTextStyle.Caption2),
                )
            }
        }

        model.output.weeks.forEach { week ->
            Row(modifier = Modifier.fillMaxWidth()) {
                week.forEach { date ->
                    Box(modifier = Modifier.weight(1f)) {
                        if (date != null) {
                            CalendarCell(
                                date = date,
                                day = model.output.day(on = date),
                                isSelected = date == selected,
                                isToday = date == model.state.today,
                                onSelect = { model.state.select(date) },
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
internal fun weekdayColor(weekday: Weekday): Color = when (weekday) {
    Weekday.sunday -> Palette.holiday
    Weekday.saturday -> Palette.saturday
    else -> Palette.subtext
}

@Composable
private fun CalendarCell(
    date: LocalDate,
    day: EntryDay?,
    isSelected: Boolean,
    isToday: Boolean,
    onSelect: () -> Unit,
) {
    val fill = if (isSelected) Palette.accent else Color.Transparent
    val rim = if (isToday && !isSelected) Palette.accent else Color.Transparent

    val numberColor = when {
        isSelected -> Palette.backgroundTop

        Holiday.contains(date) -> Palette.holiday

        else -> weekdayColor(weekday = date.weekday).takeIf { it != Palette.subtext }
            ?: Palette.text
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 62.dp)
            .clickable(onClick = onSelect)
            .padding(vertical = 2.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(
            modifier = Modifier
                .size(30.dp)
                .clip(CircleShape)
                .background(fill)
                .border(
                    width = 1.dp,
                    color = rim,
                    shape = CircleShape,
                ),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = date.day.toString(),
                color = numberColor,
                style = displayFont(size = FontSize.Body),
            )
        }

        CellTotals(day = day)
    }
}

@Composable
private fun CellTotals(day: EntryDay?) {
    if (day != null && day.expenseTotal > 0) {
        AmountText(
            amount = day.expenseTotal.toInt(),
            style = displayFont(size = FontSize.Micro),
            type = Entry.Kind.expense,
            isCompact = true,
        )
    }

    if (day != null && day.incomeTotal > 0) {
        AmountText(
            amount = day.incomeTotal.toInt(),
            style = displayFont(size = FontSize.Micro),
            type = Entry.Kind.income,
            isCompact = true,
        )
    }
}

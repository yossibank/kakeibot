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
import com.yossibank.kakeibot.featuremodels.shared.amount.AmountText
import com.yossibank.kakeibot.featuremodels.shared.amount.clamped
import com.yossibank.kakeibot.featuremodels.shared.datechoice.shortName
import com.yossibank.kakeibot.features.shared.entrylist.EntryItemRow
import com.yossibank.kakeibot.features.shared.entrylist.rememberEntryList
import com.yossibank.kakeibot.features.shared.period.PeriodStepper
import com.yossibank.kakeibot.store.database.AppDatabase
import kotlinx.coroutines.launch

@Composable
fun RecordsView(
    database: AppDatabase,
    today: LocalDate,
    onOpenEntry: (Identifier<Entry>) -> Unit,
) {
    val entryList = rememberEntryList(database)

    val model = remember(database, entryList) {
        RecordsModel(
            database = database,
            entryList = entryList,
            today = today,
        )
    }

    SideEffect {
        model.state.today = today
    }

    val scope = rememberCoroutineScope()

    LaunchedEffect(model) {
        model.observe()
    }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(
            start = 16.dp,
            top = 12.dp,
            end = 16.dp,
            bottom = 24.dp,
        ),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        item(key = "title") {
            Text(
                text = "記録",
                color = Palette.accentStrong,
                style = displayFont(size = FontSize.Headline),
            )
        }

        item(key = "month") {
            PeriodStepper(
                title = model.output.monthTitle,
                onPrevious = { model.move(months = -1) },
                onNext = { model.move(months = 1) },
                caption = model.output.periodText,
            )
        }

        item(key = "summary") {
            SummaryCard(model = model)
        }

        item(key = "layout") {
            SegmentSwitch(
                selection = model.input.layout,
                options = layouts,
                onSelect = { layout ->
                    scope.launch { model.select(layout) }
                },
            )
        }

        if (model.input.layout == RecordsLayout.calendar) {
            item(key = "calendar") {
                RecordsCalendarCard(model = model)
            }

            item(key = "selected") {
                val date = model.output.selectedDate

                DayCard(
                    day = model.output.day(on = date) ?: EntryDay(
                        date = date,
                        entries = emptyList(),
                    ),
                    model = model,
                    onOpenEntry = onOpenEntry,
                )
            }
        } else {
            if (model.input.isLoaded && model.output.days.isEmpty()) {
                item(key = "empty") {
                    EmptyCard()
                }
            }

            items(
                items = model.output.days,
                key = { it.date.toString() },
            ) { day ->
                DayCard(
                    day = day,
                    model = model,
                    onOpenEntry = onOpenEntry,
                )
            }
        }
    }
}

@Composable
private fun SummaryCard(model: RecordsModel) {
    val expense = model.output.expenseTotal.clamped
    val income = model.output.incomeTotal.clamped
    val balance = model.output.balance.clamped

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .card()
            .padding(
                horizontal = 16.dp,
                vertical = 12.dp,
            ),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            SummaryValue(
                title = "支出",
                amount = expense,
                type = Entry.Kind.expense,
                modifier = Modifier.weight(1f),
            )

            VerticalRule(height = 20.dp)

            Spacer(modifier = Modifier.width(12.dp))

            SummaryValue(
                title = "収入",
                amount = income,
                type = Entry.Kind.income,
                modifier = Modifier.weight(1f),
            )
        }

        Hairline()

        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = model.output.balanceTitle,
                modifier = Modifier.weight(1f),
                color = Palette.subtext,
                style = textFont(style = FontTextStyle.Caption),
            )

            AmountText(
                amount = balance,
                style = displayFont(
                    size = FontSize.Body,
                    weight = FontWeight.SemiBold,
                ),
                sign = AmountText.Sign.Plus,
                color = if (balance < 0) Palette.rose else Palette.accent,
            )
        }
    }
}

@Composable
private fun SummaryValue(
    title: String,
    amount: Int,
    type: Entry.Kind,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = title,
            color = Palette.subtext,
            style = textFont(style = FontTextStyle.Caption),
        )

        AmountText(
            amount = amount,
            style = displayFont(size = FontSize.Body),
            type = type,
        )
    }
}

@Composable
private fun DayCard(
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
            isToday = day.date == model.state.today,
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
    isToday: Boolean,
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
            text = date.monthDayText,
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

        if (isToday) {
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

private val layouts = listOf(
    RecordsLayout.calendar to "カレンダー",
    RecordsLayout.list to "一覧",
)

@Composable
private fun EmptyCard() {
    Text(
        text = "この月の記録はまだありません",
        modifier = Modifier
            .fillMaxWidth()
            .card()
            .padding(
                horizontal = 16.dp,
                vertical = 32.dp,
            ),
        color = Palette.subtext,
        textAlign = TextAlign.Center,
        style = textFont(style = FontTextStyle.Subheadline),
    )
}

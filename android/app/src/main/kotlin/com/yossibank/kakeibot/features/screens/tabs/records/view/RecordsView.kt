package com.yossibank.kakeibot.features.screens.tabs.records.view

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryDay
import com.yossibank.kakeibot.core.concepts.setting.RecordsLayout
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.designsystem.components.input.SegmentSwitch
import com.yossibank.kakeibot.designsystem.components.notice.noticeBanner
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
import com.yossibank.kakeibot.featuremodels.screens.tabs.review.parts.ReviewText
import com.yossibank.kakeibot.featuremodels.shared.amount.AmountText
import com.yossibank.kakeibot.featuremodels.shared.amount.clamped
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenParts
import com.yossibank.kakeibot.featuremodels.shared.model.perform
import com.yossibank.kakeibot.features.screens.tabs.review.parts.balanceColor
import com.yossibank.kakeibot.features.shared.notice.TabNoticeRound
import com.yossibank.kakeibot.features.shared.observation.rememberObservationRound
import com.yossibank.kakeibot.features.shared.period.PeriodStepper
import com.yossibank.kakeibot.features.shared.placeholder.LoadFailedColumn

@Composable
fun RecordsView(
    parts: ScreenParts,
    today: LocalDate,
    onOpenEntry: (Identifier<Entry>) -> Unit,
) {
    val round = rememberObservationRound()

    val model = remember(parts, round) {
        RecordsModel(
            parts = parts,
            today = today,
            round = round,
        )
    }

    LaunchedEffect(model) {
        model.observe()
    }

    SideEffect {
        model.setToday(today)
    }

    model.state.task.Timer()
    TabNoticeRound(model.state.task)

    LoadFailedColumn(
        isFailed = model.state.isListFailed,
        onRetry = model::retry,
    ) {
        item(key = "title") {
            Text(
                text = "記録",
                color = Palette.accentStrong,
                style = displayFont(size = FontSize.Headline),
            )
        }

        noticeBanner(task = model.state.task)

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
                onSelect = { layout -> model.perform { it.select(layout) } },
            )
        }

        if (model.input.layout == RecordsLayout.calendar) {
            item(key = "calendar") {
                RecordsCalendarCard(model = model)
            }

            item(key = "selected") {
                val date = model.output.selectedDate

                RecordsDayCard(
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
                RecordsDayCard(
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
                color = ReviewText.balanceColor(model.output.balance),
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

private val layouts = listOf(
    RecordsLayout.calendar to "カレンダー",
    RecordsLayout.list to "一覧",
)

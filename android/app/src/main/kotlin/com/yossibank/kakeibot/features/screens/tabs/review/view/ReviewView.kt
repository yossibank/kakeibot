package com.yossibank.kakeibot.features.screens.tabs.review.view

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.review.ReviewKind
import com.yossibank.kakeibot.core.concepts.review.ReviewPeriod
import com.yossibank.kakeibot.designsystem.components.icon.IconTile
import com.yossibank.kakeibot.designsystem.components.input.SegmentSwitch
import com.yossibank.kakeibot.designsystem.components.notice.noticeBanner
import com.yossibank.kakeibot.designsystem.components.surface.Hairline
import com.yossibank.kakeibot.designsystem.components.surface.VerticalRule
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.components.text.FittedText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Metrics
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.screens.tabs.review.model.ReviewModel
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
fun ReviewView(
    parts: ScreenParts,
    today: LocalDate,
) {
    val round = rememberObservationRound()

    val model = remember(parts, round) {
        ReviewModel(
            parts = parts,
            today = today,
            round = round,
        )
    }

    SideEffect {
        model.setToday(today)
    }

    LaunchedEffect(model) {
        model.observe()
    }

    model.state.task.Timer()
    TabNoticeRound(model.state.task)

    LoadFailedColumn(
        isFailed = model.state.isListFailed,
        onRetry = model::retry,
    ) {
        item(key = "title") {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = "振り返り",
                    modifier = Modifier.weight(1f),
                    color = Palette.accentStrong,
                    style = displayFont(size = FontSize.Headline),
                )

                SegmentSwitch(
                    selection = model.input.scale,
                    options = scales,
                    onSelect = { scale ->
                        model.setScale(scale)
                        model.perform { it.saveSelection() }
                    },
                )
            }
        }

        noticeBanner(task = model.state.task)

        item(key = "period") {
            PeriodStepper(
                title = model.output.title,
                onPrevious = { model.state.move(count = -1) },
                onNext = { model.state.move(count = 1) },
                caption = model.output.rangeText.takeIf {
                    model.input.scale !=
                        ReviewPeriod.Scale.week
                },
                canMoveForward = model.output.canMoveForward,
            )
        }

        item(key = "totals") {
            TotalsCard(model = model)
        }

        item(key = "breakdown") {
            BreakdownCard(model = model)
        }
    }
}

@Composable
private fun TotalsCard(model: ReviewModel) {
    val summary = model.output.summary

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .card()
            .padding(
                horizontal = 8.dp,
                vertical = 12.dp,
            ),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Total(
            title = "支出",
            amount = summary.expense.total,
            type = Entry.Kind.expense,
            modifier = Modifier.weight(1f),
        )

        VerticalRule()

        Total(
            title = "収入",
            amount = summary.income.total,
            type = Entry.Kind.income,
            modifier = Modifier.weight(1f),
        )

        VerticalRule()

        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(2.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = ReviewText.balanceTitle(summary.balance),
                color = Palette.subtext,
                style = textFont(style = FontTextStyle.Caption),
            )

            AmountText(
                amount = summary.balance.clamped,
                style = displayFont(size = FontSize.Body),
                sign = AmountText.Sign.Plus,
                color = ReviewText.balanceColor(summary.balance),
            )
        }
    }
}

@Composable
private fun Total(
    title: String,
    amount: Long,
    type: Entry.Kind,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(2.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = title,
            color = Palette.subtext,
            style = textFont(style = FontTextStyle.Caption),
        )

        AmountText(
            amount = amount.clamped,
            style = displayFont(size = FontSize.Body),
            type = type,
        )
    }
}

@Composable
private fun BreakdownCard(model: ReviewModel) {
    val rows = model.output.rows
    val bars = model.output.balanceBars
    val isBalance = model.input.kind == ReviewKind.balance
    val total = model.output.total

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .card()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = if (isBalance) "収入と支出" else "カテゴリごと",
                modifier = Modifier.weight(1f),
                color = Palette.accent,
                style = textFont(
                    style = FontTextStyle.Caption,
                    weight = FontWeight.SemiBold,
                ),
            )

            SegmentSwitch(
                selection = model.input.kind,
                options = kinds,
                onSelect = { kind ->
                    model.setKind(kind)
                    model.perform { it.saveSelection() }
                },
            )
        }

        Box(contentAlignment = Alignment.Center) {
            if (!isBalance) {
                ReviewDonut(rows = rows)
            }

            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = if (isBalance) {
                        ReviewText.balanceTitle(
                            total,
                        )
                    } else {
                        title(of = model.input.kind)
                    },
                    color = Palette.subtext,
                    style = textFont(style = FontTextStyle.Caption),
                )

                AmountText(
                    amount = total.clamped,
                    style = displayFont(
                        size = FontSize.Headline,
                        weight = FontWeight.Bold,
                    ),
                    sign = if (isBalance) AmountText.Sign.Plus else AmountText.Sign.Auto,
                    color = if (isBalance) ReviewText.balanceColor(total) else Palette.accentStrong,
                )
            }
        }

        ReviewComparison(model = model)

        if (isBalance) {
            ReviewBalanceBars(bars = bars)
        } else if (rows.isEmpty()) {
            Text(
                text = "この期間の記録はまだありません",
                modifier = Modifier.padding(vertical = 8.dp),
                color = Palette.subtext,
                style = textFont(style = FontTextStyle.Subheadline),
            )
        }

        Column(modifier = Modifier.fillMaxWidth()) {
            rows.forEach { row ->
                Hairline()

                CategoryRow(row = row)
            }
        }
    }
}

@Composable
private fun CategoryRow(row: ReviewModel.Row) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = Metrics.rowMinHeight),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        IconTile(
            icon = row.icon,
            size = 28.dp,
        )

        FittedText(
            text = row.name,
            modifier = Modifier.weight(1f),
            color = Palette.text,
            style = textFont(style = FontTextStyle.Subheadline),
        )

        row.percent?.let { percent ->
            Text(
                text = percent,
                color = Palette.subtext,
                style = textFont(style = FontTextStyle.Caption),
            )
        }

        AmountText(
            amount = row.amount.clamped,
            style = displayFont(size = FontSize.Body),
            color = Palette.text,
        )
    }
}

private fun title(of: ReviewKind): String = when (of) {
    ReviewKind.expense -> "支出"
    ReviewKind.income -> "収入"
    ReviewKind.balance -> "収支"
}

private val scales = listOf(
    ReviewPeriod.Scale.week to "週",
    ReviewPeriod.Scale.month to "月",
    ReviewPeriod.Scale.year to "年",
)

private val kinds = ReviewKind.entries.map { it to title(of = it) }

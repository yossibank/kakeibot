package com.yossibank.kakeibot.features.screens.tabs.review.view

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
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
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.title
import com.yossibank.kakeibot.core.concepts.review.ReviewPeriod
import com.yossibank.kakeibot.designsystem.components.icon.IconTile
import com.yossibank.kakeibot.designsystem.components.input.SegmentSwitch
import com.yossibank.kakeibot.designsystem.components.surface.Hairline
import com.yossibank.kakeibot.designsystem.components.surface.VerticalRule
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.components.text.FittedText
import com.yossibank.kakeibot.designsystem.components.text.clamped
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Metrics
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.colorOf
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.features.screens.tabs.review.model.ReviewModel
import com.yossibank.kakeibot.features.shared.entrylist.rememberEntryList
import com.yossibank.kakeibot.features.shared.period.PeriodStepper
import com.yossibank.kakeibot.store.database.AppDatabase
import kotlin.math.roundToInt

@Composable
fun ReviewView(
    database: AppDatabase,
    today: LocalDate,
) {
    val entryList = rememberEntryList(database)

    val model = remember(database, entryList) {
        ReviewModel(
            database = database,
            entryList = entryList,
            today = today,
        )
    }

    SideEffect {
        model.state.today = today
    }

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
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = "振り返り",
                    modifier = Modifier.weight(1f),
                    color = Palette.accentStrong,
                    style = displayFont(size = FontSize.Headline),
                )

                SegmentSwitch(
                    selection = model.state.scale,
                    options = scales,
                    onSelect = model.state::select,
                )
            }
        }

        item(key = "period") {
            PeriodStepper(
                title = model.output.title,
                onPrevious = { model.state.move(count = -1) },
                onNext = { model.state.move(count = 1) },
                caption = model.output.rangeText.takeIf {
                    model.state.scale !=
                        ReviewPeriod.Scale.week
                },
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
                text = if (summary.balance < 0) "収支 · 赤字" else "収支 · 黒字",
                color = Palette.subtext,
                style = textFont(style = FontTextStyle.Caption),
            )

            AmountText(
                amount = summary.balance.clamped,
                style = displayFont(size = FontSize.Body),
                sign = AmountText.Sign.Plus,
                color = if (summary.balance < 0) Palette.rose else Palette.accent,
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
    val difference = model.output.total - model.output.previousTotal

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
                text = "カテゴリごと",
                modifier = Modifier.weight(1f),
                color = Palette.accent,
                style = textFont(
                    style = FontTextStyle.Caption,
                    weight = FontWeight.SemiBold,
                ),
            )

            SegmentSwitch(
                selection = model.state.kind,
                options = kinds,
                onSelect = { model.state.kind = it },
            )
        }

        Box(contentAlignment = Alignment.Center) {
            Donut(rows = rows)

            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = model.state.kind.title,
                    color = Palette.subtext,
                    style = textFont(style = FontTextStyle.Caption),
                )

                AmountText(
                    amount = model.output.total.clamped,
                    style = displayFont(
                        size = FontSize.Headline,
                        weight = FontWeight.Bold,
                    ),
                    color = Palette.accentStrong,
                )
            }
        }

        Text(
            text = "前の期間の同じ時点より ${AmountText.text(
                amount = difference.clamped,
                sign = AmountText.Sign.Plus,
            )}",
            color = Palette.subtext,
            style = textFont(style = FontTextStyle.Caption),
        )

        if (rows.isEmpty()) {
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

        Text(
            text = "${(row.ratio * 100).roundToInt()}%",
            color = Palette.subtext,
            style = textFont(style = FontTextStyle.Caption),
        )

        AmountText(
            amount = row.amount.clamped,
            style = displayFont(size = FontSize.Body),
            color = Palette.text,
        )
    }
}

@Composable
private fun Donut(rows: List<ReviewModel.Row>) {
    val track = Palette.accent.opacity(Emphasis.Subtle)
    val other = Palette.subtext.opacity(Emphasis.Medium)

    val slices = rows.take(DONUT_SLICES).map { row ->
        (row.color?.let { colorOf(hex = it) } ?: other) to row.ratio
    }

    val rest = rows.drop(DONUT_SLICES).sumOf { it.ratio }

    Canvas(modifier = Modifier.size(200.dp)) {
        val stroke = 22.dp.toPx()

        val box = Size(
            width = size.width - stroke,
            height = size.height - stroke,
        )

        val corner = Offset(
            x = stroke / 2,
            y = stroke / 2,
        )

        drawArc(
            color = track,
            startAngle = 0f,
            sweepAngle = 360f,
            useCenter = false,
            topLeft = corner,
            size = box,
            style = Stroke(width = stroke),
        )

        var start = -90f

        (slices + (other to rest)).forEach { (color, ratio) ->
            val sweep = (360 * ratio).toFloat()

            if (sweep > 0f) {
                drawArc(
                    color = color,
                    startAngle = start,
                    sweepAngle = (sweep - GAP_DEGREES).coerceAtLeast(0.5f),
                    useCenter = false,
                    topLeft = corner,
                    size = box,
                    style = Stroke(width = stroke),
                )
            }

            start += sweep
        }
    }
}

private const val DONUT_SLICES = 5
private const val GAP_DEGREES = 1.5f

private val scales = listOf(
    ReviewPeriod.Scale.week to "週",
    ReviewPeriod.Scale.month to "月",
    ReviewPeriod.Scale.year to "年",
)

private val kinds = listOf(Entry.Kind.expense, Entry.Kind.income).map { it to it.title }

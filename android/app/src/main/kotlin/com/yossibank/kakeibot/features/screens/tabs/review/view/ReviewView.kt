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
import com.yossibank.kakeibot.core.concepts.review.ReviewPeriod
import com.yossibank.kakeibot.designsystem.components.icon.IconTile
import com.yossibank.kakeibot.designsystem.components.input.SegmentSwitch
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.colorOf
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.features.screens.tabs.review.model.ReviewModel
import com.yossibank.kakeibot.store.database.AppDatabase
import kotlin.math.roundToInt

@Composable
fun ReviewView(
    database: AppDatabase,
    today: LocalDate,
) {
    val model = remember(database) {
        ReviewModel(
            database = database,
            today = today,
        )
    }

    SideEffect {
        model.today = today
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
                    selection = model.scale,
                    options = scales,
                    onSelect = model::select,
                )
            }
        }

        item(key = "period") {
            PeriodHeader(model = model)
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
private fun PeriodHeader(model: ReviewModel) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        PeriodButton(
            rotation = 180f,
            onSelect = { model.move(count = -1) },
        )

        Column(
            modifier = Modifier.weight(1f),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = model.title,
                color = Palette.accentStrong,
                style = displayFont(size = FontSize.Headline),
            )

            if (model.scale != ReviewPeriod.Scale.week) {
                Text(
                    text = model.rangeText,
                    color = Palette.subtext,
                    style = textFont(style = FontTextStyle.Caption),
                )
            }
        }

        PeriodButton(
            rotation = 0f,
            onSelect = { model.move(count = 1) },
        )
    }
}

@Composable
private fun PeriodButton(
    rotation: Float,
    onSelect: () -> Unit,
) {
    Box(
        modifier = Modifier
            .size(40.dp)
            .clip(CircleShape)
            .clickable(onClick = onSelect),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            painter = painterResource(R.drawable.ic_chevron_right),
            contentDescription = null,
            modifier = Modifier
                .size(24.dp)
                .rotate(rotation),
            tint = Palette.accent,
        )
    }
}

@Composable
private fun TotalsCard(model: ReviewModel) {
    val summary = model.summary

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

        Separator()

        Total(
            title = "収入",
            amount = summary.income.total,
            type = Entry.Kind.income,
            modifier = Modifier.weight(1f),
        )

        Separator()

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
    val rows = model.rows
    val difference = model.total - model.previousTotal

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
                selection = model.kind,
                options = kinds,
                onSelect = { model.kind = it },
            )
        }

        Box(contentAlignment = Alignment.Center) {
            Donut(rows = rows)

            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = if (model.kind == Entry.Kind.income) "収入" else "支出",
                    color = Palette.subtext,
                    style = textFont(style = FontTextStyle.Caption),
                )

                AmountText(
                    amount = model.total.clamped,
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
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(1.dp)
                        .background(Palette.line),
                )

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
            .heightIn(min = 52.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        IconTile(
            icon = row.icon,
            size = 28.dp,
        )

        Text(
            text = row.name,
            modifier = Modifier.weight(1f),
            color = Palette.text,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
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

@Composable
private fun Separator() {
    Box(
        modifier = Modifier
            .width(1.dp)
            .height(28.dp)
            .background(Palette.line),
    )
}

private const val DONUT_SLICES = 5
private const val GAP_DEGREES = 1.5f

private val scales = listOf(
    ReviewPeriod.Scale.week to "週",
    ReviewPeriod.Scale.month to "月",
    ReviewPeriod.Scale.year to "年",
)

private val kinds = listOf(
    Entry.Kind.expense to "支出",
    Entry.Kind.income to "収入",
)

private val Long.clamped: Int
    get() = coerceIn(Int.MIN_VALUE.toLong(), Int.MAX_VALUE.toLong()).toInt()

package com.yossibank.kakeibot.features.screens.tabs.review.view

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.colorOf
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.featuremodels.screens.tabs.review.model.ReviewModel

@Composable
fun ReviewDonut(rows: List<ReviewModel.Row>) {
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

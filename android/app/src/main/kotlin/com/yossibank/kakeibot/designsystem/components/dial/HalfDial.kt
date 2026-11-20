package com.yossibank.kakeibot.designsystem.components.dial

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.opacity
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

@Composable
fun HalfDial(
    progress: Double,
    modifier: Modifier = Modifier,
    color: Color = Palette.accent,
) {
    val track = Palette.accent.opacity(Emphasis.Soft)
    val tick = Palette.accent.opacity(Emphasis.Medium)
    val major = Palette.accentStrong

    Canvas(
        modifier = modifier
            .fillMaxWidth()
            .aspectRatio(2f),
    ) {
        val stroke = 2.dp.toPx()
        val radius = size.width / 2 - stroke
        val center = Offset(
            x = size.width / 2,
            y = size.height - stroke,
        )

        val box = Size(
            width = radius * 2,
            height = radius * 2,
        )

        val corner = Offset(
            x = center.x - radius,
            y = center.y - radius,
        )

        drawArc(
            color = track,
            startAngle = 180f,
            sweepAngle = 180f,
            useCenter = false,
            topLeft = corner,
            size = box,
            style = Stroke(
                width = stroke,
                cap = StrokeCap.Round,
            ),
        )

        drawArc(
            color = color,
            startAngle = 180f,
            sweepAngle = (180 * progress.coerceIn(0.0, 1.0)).toFloat(),
            useCenter = false,
            topLeft = corner,
            size = box,
            style = Stroke(
                width = stroke,
                cap = StrokeCap.Round,
            ),
        )

        repeat(TICKS + 1) { index ->
            val isMajor = index % MAJOR_EVERY == 0
            val angle = PI * index / TICKS
            val outer = radius - 10.dp.toPx()
            val inner = outer - (if (isMajor) 14.dp else 7.dp).toPx()

            drawLine(
                color = if (isMajor) major else tick,
                start = Offset(
                    x = center.x - (cos(angle) * inner).toFloat(),
                    y = center.y - (sin(angle) * inner).toFloat(),
                ),
                end = Offset(
                    x = center.x - (cos(angle) * outer).toFloat(),
                    y = center.y - (sin(angle) * outer).toFloat(),
                ),
                strokeWidth = (if (isMajor) 1.5.dp else 0.75.dp).toPx(),
                cap = StrokeCap.Round,
            )
        }
    }
}

private const val TICKS = 30
private const val MAJOR_EVERY = 5

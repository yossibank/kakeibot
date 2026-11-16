package com.yossibank.kakeibot.designsystem.components.dial

import androidx.compose.foundation.Canvas
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.sin

@Composable
fun DialTicks(
    count: Int,
    length: Dp,
    color: Color,
    lineWidth: Dp,
    modifier: Modifier = Modifier,
) {
    Canvas(modifier = modifier) {
        val outer = min(size.width, size.height) / 2
        val inner = outer - length.toPx()

        repeat(count) { index ->
            val angle = index.toDouble() / count * 2 * PI

            drawLine(
                color = color,
                start = point(
                    from = center,
                    angle = angle,
                    radius = inner,
                ),
                end = point(
                    from = center,
                    angle = angle,
                    radius = outer,
                ),
                strokeWidth = lineWidth.toPx(),
            )
        }
    }
}

private fun point(
    from: Offset,
    angle: Double,
    radius: Float,
): Offset = Offset(
    x = from.x + (sin(angle) * radius).toFloat(),
    y = from.y - (cos(angle) * radius).toFloat(),
)

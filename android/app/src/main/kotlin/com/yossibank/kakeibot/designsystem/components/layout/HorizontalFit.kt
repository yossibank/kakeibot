package com.yossibank.kakeibot.designsystem.components.layout

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.layout.Measurable
import androidx.compose.ui.layout.Placeable

@Composable
fun HorizontalFit(
    wide: @Composable () -> Unit,
    narrow: @Composable () -> Unit,
    modifier: Modifier = Modifier,
) {
    Layout(
        contents = listOf(wide, narrow),
        modifier = modifier,
    ) { (wideMeasurables, narrowMeasurables), constraints ->
        val needed = wideMeasurables.maxOfOrNull { it.maxIntrinsicWidth(constraints.maxHeight) }
        val fits = (needed ?: 0) <= constraints.maxWidth
        val chosen: List<Measurable> = if (fits) wideMeasurables else narrowMeasurables
        val loose = constraints.copy(minWidth = 0)
        val placeables: List<Placeable> = chosen.map { it.measure(loose) }
        val width = (placeables.maxOfOrNull { it.width } ?: 0).coerceAtLeast(constraints.minWidth)
        val height = placeables.maxOfOrNull { it.height } ?: 0

        layout(
            width = width,
            height = height,
        ) {
            placeables.forEach { it.place(x = 0, y = 0) }
        }
    }
}

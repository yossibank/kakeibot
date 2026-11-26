package com.yossibank.kakeibot.designsystem.components.tag

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.designsystem.theme.Palette
import kotlin.math.PI
import kotlin.math.sin

data class TagLineItem<Id>(
    val id: Id,
    val name: String,
)

@Composable
fun <Id> TagLine(
    tags: List<TagLineItem<Id>>,
    selection: Id?,
    onSelect: (Id) -> Unit,
    modifier: Modifier = Modifier,
) {
    val outline = Palette.outline

    BoxWithConstraints(
        modifier = modifier
            .fillMaxWidth()
            .height(lineHeight),
    ) {
        val lineWidth = maxWidth

        Canvas(
            modifier = Modifier
                .fillMaxWidth()
                .height(sag),
        ) {
            val path = Path().apply {
                moveTo(0f, 4.dp.toPx())
                quadraticTo(size.width / 2, size.height, size.width, 4.dp.toPx())
            }

            drawPath(
                path = path,
                color = outline,
                style = Stroke(width = 0.8.dp.toPx()),
            )
        }

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState())
                .widthIn(min = lineWidth)
                .padding(horizontal = inset),
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            tags.forEachIndexed { index, tag ->
                Hanging(
                    modifier = Modifier.padding(start = if (index == 0) 0.dp else spacing),
                    title = tag.name,
                    isSelected = tag.id == selection,
                    drop = drop(
                        at = index,
                        count = tags.size,
                    ),
                    tilt = tilts[index % tilts.size],
                    onSelect = { onSelect(tag.id) },
                )
            }
        }
    }
}

@Composable
private fun Hanging(
    title: String,
    isSelected: Boolean,
    drop: Dp,
    tilt: Float,
    onSelect: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val rotation by animateFloatAsState(
        targetValue = if (isSelected) 0f else tilt,
        animationSpec = spring(dampingRatio = 0.5f),
        label = "tilt",
    )

    Column(
        modifier = modifier
            .padding(top = inset)
            .graphicsLayer {
                rotationZ = rotation
                transformOrigin = TransformOrigin(0.5f, 0f)
            }.clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                onClick = onSelect,
            ),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(
            modifier = Modifier
                .width(0.8.dp)
                .height(drop)
                .background(Palette.outline),
        )

        TagCard(
            title = title,
            style = if (isSelected) TagCardStyle.Selected else TagCardStyle.Plain,
        )
    }
}

private fun drop(
    at: Int,
    count: Int,
): Dp {
    val position = (at + 0.5) / maxOf(count, 1)
    return (6 + 7 * sin(PI * position)).dp
}

private val lineHeight: Dp = 54.dp
private val sag: Dp = 20.dp
private val spacing: Dp = 8.dp
private val inset: Dp = 4.dp
private val tilts = listOf(-3f, 2f, -1f, 3f, -2f)

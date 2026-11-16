package com.yossibank.kakeibot.designsystem.components.navigation

import androidx.annotation.DrawableRes
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.em
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.designsystem.components.dial.DialTicks
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.Haptic
import com.yossibank.kakeibot.designsystem.theme.HapticEffect
import com.yossibank.kakeibot.designsystem.theme.LocalThemeStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.glow
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont
import kotlin.math.floor

object FloatingTabBar {
    val height: Dp = 64.dp
    val clearance: Dp = height + bottomGap

    internal val bottomGap: Dp
        get() = 4.dp

    data class Item<Value>(
        val title: String,
        @param:DrawableRes val icon: Int,
        val value: Value,
    )
}

@Composable
fun <Value> FloatingTabBar(
    selection: Value,
    items: List<FloatingTabBar.Item<Value>>,
    onSelect: (Value) -> Unit,
    onAdd: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .padding(bottom = FloatingTabBar.bottomGap),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Tabs(
            selection = selection,
            items = items,
            onSelect = onSelect,
            modifier = Modifier.weight(1f),
        )

        AddButton(onAdd = onAdd)
    }
}

@Composable
private fun <Value> Tabs(
    selection: Value,
    items: List<FloatingTabBar.Item<Value>>,
    onSelect: (Value) -> Unit,
    modifier: Modifier = Modifier,
) {
    var barWidth by remember { mutableIntStateOf(0) }
    var dragX by remember { mutableStateOf<Float?>(null) }

    val currentItems by rememberUpdatedState(items)
    val currentOnSelect by rememberUpdatedState(onSelect)

    val itemWidth = if (items.isEmpty()) 0f else barWidth.toFloat() / items.size
    val selectedIndex = items.indexOfFirst { it.value == selection }.takeIf { it >= 0 }

    val highlightedIndex = dragX?.let { x ->
        index(
            x = x,
            itemWidth = itemWidth,
            count = items.size,
        )
    } ?: selectedIndex

    HapticEffect(
        haptic = Haptic.Selection,
        trigger = highlightedIndex,
    )

    Box(
        modifier = modifier
            .glass(tint = Palette.backgroundBottom)
            .background(
                brush = TabBarStyle.sheen,
                shape = CircleShape,
            )
            .border(
                width = 1.dp,
                brush = TabBarStyle.rim,
                shape = CircleShape,
            )
            .padding(8.dp),
    ) {
        Indicator(
            itemWidth = itemWidth,
            barWidth = barWidth,
            dragX = dragX,
            selectedIndex = selectedIndex,
            isShown = barWidth > 0 && highlightedIndex != null,
        )

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .onSizeChanged { barWidth = it.width }
                .pointerInput(Unit) {
                    awaitEachGesture {
                        val down = awaitFirstDown()
                        var x = down.position.x

                        dragX = x

                        while (true) {
                            val event = awaitPointerEvent()
                            val change = event.changes.firstOrNull { it.id == down.id } ?: break

                            x = change.position.x

                            if (!change.pressed) {
                                break
                            }

                            dragX = x
                            change.consume()
                        }

                        val count = currentItems.size
                        val width = if (count == 0) 0f else size.width.toFloat() / count

                        val selected = index(
                            x = x,
                            itemWidth = width,
                            count = currentItems.size,
                        )

                        dragX = null

                        if (selected != null) {
                            currentOnSelect(currentItems[selected].value)
                        }
                    }
                },
        ) {
            items.forEachIndexed { index, item ->
                TabItem(
                    item = item,
                    isHighlighted = index == highlightedIndex,
                    modifier = Modifier.weight(1f),
                )
            }
        }
    }
}

@Composable
private fun Indicator(
    itemWidth: Float,
    barWidth: Int,
    dragX: Float?,
    selectedIndex: Int?,
    isShown: Boolean,
) {
    val isDragging = dragX != null
    val fill = Palette.accent.opacity(if (isDragging) Emphasis.Soft else Emphasis.Subtle)

    val target = if (dragX == null) {
        itemWidth * (selectedIndex ?: 0)
    } else {
        (dragX - itemWidth / 2).coerceIn(0f, (barWidth - itemWidth).coerceAtLeast(0f))
    }

    val x by animateFloatAsState(
        targetValue = target,
        animationSpec = spring(
            dampingRatio = 0.8f,
            stiffness = if (isDragging) 1200f else 320f,
        ),
        label = "indicatorX",
    )

    val scale by animateFloatAsState(
        targetValue = if (isDragging) 1.08f else 1f,
        label = "indicatorScale",
    )

    val density = LocalDensity.current

    Box(
        modifier = Modifier
            .offset {
                IntOffset(
                    x = x.toInt(),
                    y = 0,
                )
            }
            .width(with(density) { itemWidth.toDp() })
            .height(FloatingTabBar.height - 12.dp)
            .alpha(if (isShown) 1f else 0f)
            .scale(scale)
            .background(
                color = fill,
                shape = CircleShape,
            )
            .border(
                width = 0.8.dp,
                brush = TabBarStyle.indicatorRim,
                shape = CircleShape,
            ),
    )
}

@Composable
private fun <Value> TabItem(
    item: FloatingTabBar.Item<Value>,
    isHighlighted: Boolean,
    modifier: Modifier = Modifier,
) {
    val showsTitles = LocalThemeStyle.current.showsTabTitles
    val iconColor = if (isHighlighted) Palette.accent else Palette.subtext
    val titleColor = if (isHighlighted) Palette.accentStrong else Palette.subtext
    val iconSize = if (showsTitles) 24.dp else 28.dp

    Column(
        modifier = modifier.height(FloatingTabBar.height - 12.dp),
        verticalArrangement = Arrangement.spacedBy(
            space = 4.dp,
            alignment = Alignment.CenterVertically,
        ),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(
            painter = painterResource(item.icon),
            contentDescription = null,
            modifier = Modifier.size(iconSize),
            tint = iconColor,
        )

        if (showsTitles) {
            Text(
                text = item.title,
                color = titleColor,
                style = textFont(size = FontSize.Caption).copy(letterSpacing = 0.05.em),
                maxLines = 1,
            )
        }
    }
}

@Composable
private fun AddButton(onAdd: () -> Unit) {
    var addCount by remember { mutableIntStateOf(0) }

    val interaction = remember { MutableInteractionSource() }
    val isPressed by interaction.collectIsPressedAsState()

    val scale by animateFloatAsState(
        targetValue = if (isPressed) 0.92f else 1f,
        animationSpec = spring(stiffness = 600f),
        label = "addScale",
    )

    HapticEffect(
        haptic = Haptic.Impact,
        trigger = addCount,
    )

    Box(
        modifier = Modifier
            .size(FloatingTabBar.height)
            .scale(scale)
            .glow(
                color = Palette.glow.opacity(Emphasis.Muted),
                radius = 14.dp,
            )
            .glass(tint = Palette.backgroundBottom)
            .background(
                brush = TabBarStyle.sheen,
                shape = CircleShape,
            )
            .border(
                width = 1.2.dp,
                brush = TabBarStyle.ring(hasDecorations = LocalThemeStyle.current.decorations),
                shape = CircleShape,
            )
            .clip(CircleShape)
            .clickable(
                interactionSource = interaction,
                indication = null,
            ) {
                addCount += 1
                onAdd()
            },
        contentAlignment = Alignment.Center,
    ) {
        DialTicks(
            count = 12,
            length = 4.dp,
            color = Palette.accent.opacity(Emphasis.Strong),
            lineWidth = 1.dp,
            modifier = Modifier
                .fillMaxSize()
                .padding(8.dp),
        )

        Icon(
            painter = painterResource(R.drawable.ic_plus),
            contentDescription = null,
            modifier = Modifier.size(24.dp),
            tint = Palette.accentStrong,
        )
    }
}

private fun Modifier.glass(tint: Color): Modifier = background(
    color = tint.copy(alpha = 0.92f),
    shape = CircleShape,
)

private fun index(
    x: Float,
    itemWidth: Float,
    count: Int,
): Int? {
    if (itemWidth <= 0 || count == 0) {
        return null
    }

    return floor(x / itemWidth).toInt().coerceIn(0, count - 1)
}

package com.yossibank.kakeibot.designsystem.components.icon

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.LocalContentColor
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.LocalThemeStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.colorOf
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.radius

@Composable
fun IconTile(
    icon: Icon?,
    size: Dp,
    modifier: Modifier = Modifier,
) {
    val shape = RoundedCornerShape(LocalThemeStyle.current.corner.radius(size / 4))
    val color = icon?.let { colorOf(hex = it.color) } ?: Palette.accent

    Box(
        modifier = modifier
            .size(size)
            .background(
                color = color.opacity(Emphasis.Subtle),
                shape = shape,
            ).border(
                width = 1.dp,
                color = color.opacity(Emphasis.Medium),
                shape = shape,
            ),
        contentAlignment = Alignment.Center,
    ) {
        CompositionLocalProvider(LocalContentColor provides Palette.text) {
            IconImage(
                icon = icon,
                size = size * 0.44f,
            )
        }
    }
}

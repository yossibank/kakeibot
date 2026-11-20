package com.yossibank.kakeibot.designsystem.components.surface

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.LocalThemeStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.radius

@Composable
fun Modifier.card(cornerRadius: Dp = 24.dp): Modifier {
    val shape = RoundedCornerShape(LocalThemeStyle.current.corner.radius(cornerRadius))

    return clip(shape)
        .background(Palette.card)
        .border(
            width = 1.dp,
            color = Palette.accent.opacity(Emphasis.Muted),
            shape = shape,
        )
}

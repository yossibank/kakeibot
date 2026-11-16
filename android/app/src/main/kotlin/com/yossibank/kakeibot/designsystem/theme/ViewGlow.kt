package com.yossibank.kakeibot.designsystem.theme

import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.unit.Dp

@Composable
fun Modifier.glow(
    color: Color,
    radius: Dp,
    shape: Shape = CircleShape,
): Modifier {
    val shown = if (LocalThemeStyle.current.decorations) color else Color.Transparent

    return shadow(
        elevation = radius,
        shape = shape,
        clip = false,
        ambientColor = shown,
        spotColor = shown,
    )
}

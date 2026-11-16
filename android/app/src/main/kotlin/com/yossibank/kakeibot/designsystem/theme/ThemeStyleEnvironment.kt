package com.yossibank.kakeibot.designsystem.theme

import androidx.compose.runtime.Composable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.core.concepts.theme.ThemeCorner
import com.yossibank.kakeibot.core.concepts.theme.ThemeStyle
import kotlin.math.roundToInt

val LocalThemeStyle = staticCompositionLocalOf { ThemeStyle.standard }

val bodyFont: TextStyle
    @Composable
    get() = textFont(style = FontTextStyle.Body)

fun ThemeCorner.radius(base: Dp): Dp = (base.value * scale).roundToInt().dp

package com.yossibank.kakeibot.designsystem.theme

import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.core.concepts.theme.ThemeFont

@Composable
fun displayFont(
    size: FontSize,
    weight: FontWeight = FontWeight.Normal,
): TextStyle = themeFont(
    font = LocalThemeStyle.current.displayFont,
    base = size.rawValue,
    weight = weight,
)

@Composable
fun displayFont(
    style: FontTextStyle,
    weight: FontWeight? = null,
): TextStyle = themeFont(
    font = LocalThemeStyle.current.displayFont,
    base = style.baseSize,
    weight = weight,
)

@Composable
fun sansFont(
    size: FontSize,
    weight: FontWeight = FontWeight.Normal,
): TextStyle = fixedFont(
    family = FontFamily.Default,
    base = size.rawValue,
    weight = weight,
)

@Composable
fun textFont(
    style: FontTextStyle,
    weight: FontWeight? = null,
): TextStyle = themeFont(
    font = LocalThemeStyle.current.textFont,
    base = style.baseSize,
    weight = weight,
)

@Composable
fun textFont(
    size: FontSize,
    weight: FontWeight = FontWeight.Normal,
): TextStyle = themeFont(
    font = LocalThemeStyle.current.textFont,
    base = size.rawValue,
    weight = weight,
)

@Composable
private fun themeFont(
    font: ThemeFont,
    base: Float,
    weight: FontWeight?,
): TextStyle = fixedFont(
    family = font.family,
    base = base,
    weight = weight,
)

@Composable
private fun fixedFont(
    family: FontFamily,
    base: Float,
    weight: FontWeight?,
): TextStyle {
    val points = FontSize.points(
        base = base,
        scale = LocalThemeStyle.current.textSize.scale,
        shared = LocalSharedTextScale.current,
    )

    val size = with(LocalDensity.current) {
        points.dp.toSp()
    }

    return TextStyle(
        fontFamily = family,
        fontSize = size,
        fontWeight = weight,
    )
}

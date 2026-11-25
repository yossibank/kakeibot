package com.yossibank.kakeibot.designsystem.components.tag

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.designsystem.components.text.FittedText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.LocalThemeStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.radius
import com.yossibank.kakeibot.designsystem.theme.textFont

@Composable
fun TagCard(
    title: String,
    style: TagCardStyle = TagCardStyle.Plain,
    modifier: Modifier = Modifier,
    size: TagCardSize = TagCardSize.Regular,
) {
    val radius = LocalThemeStyle.current.corner.radius(4.dp)
    val shape = RoundedCornerShape(radius)
    val stroke = style.stroke

    val outlined = if (style == TagCardStyle.Add) {
        modifier.drawBehind {
            drawRoundRect(
                color = stroke,
                cornerRadius = CornerRadius(radius.toPx()),
                style = Stroke(
                    width = 1.dp.toPx(),
                    pathEffect = PathEffect.dashPathEffect(floatArrayOf(3.dp.toPx(), 2.dp.toPx())),
                ),
            )
        }
    } else {
        modifier
            .background(
                color = style.fill,
                shape = shape,
            ).border(
                width = 1.dp,
                color = stroke,
                shape = shape,
            )
    }

    Box(
        modifier = outlined.defaultMinSize(
            minWidth = size.minWidth,
            minHeight = size.height,
        ),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            modifier = Modifier
                .align(Alignment.TopCenter)
                .padding(top = size.holeTop)
                .size(size.hole)
                .border(
                    width = 0.8.dp,
                    color = stroke,
                    shape = CircleShape,
                ),
        )

        FittedText(
            text = title,
            modifier = Modifier.padding(
                start = size.padding,
                end = size.padding,
                top = 4.dp,
            ),
            color = style.foreground,
            style = textFont(size = size.font),
        )
    }
}

enum class TagCardStyle {
    Plain,
    Selected,
    Add,
}

enum class TagCardSize(
    internal val font: FontSize,
    internal val height: Dp,
    internal val minWidth: Dp,
    internal val padding: Dp,
    internal val hole: Dp,
    internal val holeTop: Dp,
) {
    Regular(
        font = FontSize.Caption,
        height = 30.dp,
        minWidth = 56.dp,
        padding = 8.dp,
        hole = 4.dp,
        holeTop = 4.dp,
    ),
    Small(
        font = FontSize.Micro,
        height = 18.dp,
        minWidth = 0.dp,
        padding = 4.dp,
        hole = 3.dp,
        holeTop = 2.dp,
    ),
}

private val TagCardStyle.foreground: Color
    @Composable get() = when (this) {
        TagCardStyle.Plain -> Palette.subtext
        TagCardStyle.Selected -> Palette.accentStrong
        TagCardStyle.Add -> Palette.accent
    }

private val TagCardStyle.fill: Color
    @Composable get() = when (this) {
        TagCardStyle.Plain -> Palette.panel
        TagCardStyle.Selected -> Palette.accent.opacity(Emphasis.Soft)
        TagCardStyle.Add -> Color.Transparent
    }

private val TagCardStyle.stroke: Color
    @Composable get() = when (this) {
        TagCardStyle.Plain -> Palette.accent.opacity(Emphasis.Muted)
        TagCardStyle.Selected -> Palette.accent
        TagCardStyle.Add -> Palette.accent.opacity(Emphasis.Medium)
    }

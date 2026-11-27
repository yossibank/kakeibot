package com.yossibank.kakeibot.designsystem.components.entry

import androidx.compose.animation.animateContentSize
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.InlineTextContent
import androidx.compose.foundation.text.appendInlineContent
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.Placeholder
import androidx.compose.ui.text.PlaceholderVerticalAlign
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Haptic
import com.yossibank.kakeibot.designsystem.theme.HapticEffect
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont

@Composable
fun EntryMemoText(
    text: String,
    modifier: Modifier = Modifier,
) {
    var isExpanded by remember { mutableStateOf(false) }
    var isTruncated by remember { mutableStateOf(false) }
    var lineHeight by remember { mutableFloatStateOf(0f) }
    val canExpand = isExpanded || isTruncated
    val angle by animateFloatAsState(if (isExpanded) 270f else 90f)
    val toggleWidth = with(LocalDensity.current) { TOGGLE_WIDTH.toSp() }
    val shown = shownText(text = text, isExpanded = isExpanded)
    val room = roomContent(width = toggleWidth)

    HapticEffect(
        haptic = Haptic.Selection,
        trigger = isExpanded,
    )

    Box(
        modifier = modifier
            .clickable(
                interactionSource = null,
                indication = null,
                enabled = canExpand,
                onClick = { isExpanded = !isExpanded },
            ),
    ) {
        Text(
            text = shown,
            modifier = Modifier
                .padding(start = 8.dp)
                .animateContentSize()
                .graphicsLayer { compositingStrategy = CompositingStrategy.Offscreen }
                .fade(
                    isShown = { isTruncated && !isExpanded },
                    lineHeight = { lineHeight },
                ),
            color = Palette.subtext,
            maxLines = if (isExpanded) Int.MAX_VALUE else LINE_LIMIT,
            inlineContent = room,
            onTextLayout = { layout ->
                val last = layout.lineCount - 1
                isTruncated = layout.hasVisualOverflow
                lineHeight = layout.getLineBottom(last) - layout.getLineTop(last)
            },
            style = textFont(style = FontTextStyle.Caption),
        )

        MemoLine()

        if (canExpand) {
            ToggleMark(angle = angle)
        }
    }
}

@Composable
private fun BoxScope.MemoLine() {
    Box(modifier = Modifier.matchParentSize()) {
        Box(
            modifier = Modifier
                .width(2.dp)
                .fillMaxHeight()
                .background(
                    color = Palette.accent.opacity(Emphasis.Medium),
                    shape = CircleShape,
                ),
        )
    }
}

@Composable
private fun BoxScope.ToggleMark(angle: Float) {
    Icon(
        painter = painterResource(R.drawable.ic_chevron_right),
        contentDescription = null,
        modifier = Modifier
            .align(Alignment.BottomEnd)
            .size(
                width = TOGGLE_WIDTH,
                height = 16.dp,
            ).padding(4.dp)
            .rotate(angle),
        tint = Palette.accent,
    )
}

private fun Modifier.fade(
    isShown: () -> Boolean,
    lineHeight: () -> Float,
): Modifier = drawWithContent {
    drawContent()

    if (isShown()) {
        val fade = FADE_WIDTH.toPx()
        val height = lineHeight()

        drawRect(
            brush = Brush.horizontalGradient(
                0f to Color.Black,
                0.55f to Color.Transparent,
                startX = size.width - fade,
                endX = size.width,
            ),
            topLeft = Offset(
                x = size.width - fade,
                y = size.height - height,
            ),
            size = Size(
                width = fade,
                height = height,
            ),
            blendMode = BlendMode.DstIn,
        )
    }
}

private fun shownText(
    text: String,
    isExpanded: Boolean,
): AnnotatedString = buildAnnotatedString {
    append(text)

    if (isExpanded) {
        appendInlineContent(ROOM)
    }
}

private fun roomContent(width: TextUnit): Map<String, InlineTextContent> = mapOf(
    ROOM to InlineTextContent(
        Placeholder(
            width = width,
            height = width / 20,
            placeholderVerticalAlign = PlaceholderVerticalAlign.TextBottom,
        ),
    ) {},
)

private const val LINE_LIMIT = 2
private const val ROOM = "room"

private val FADE_WIDTH = 72.dp
private val TOGGLE_WIDTH = 20.dp

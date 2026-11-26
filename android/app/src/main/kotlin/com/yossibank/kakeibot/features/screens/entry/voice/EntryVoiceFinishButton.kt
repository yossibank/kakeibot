package com.yossibank.kakeibot.features.screens.entry.voice

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont

@Composable
fun EntryVoiceFinishButton(
    silenceStart: Long?,
    duration: Long,
    passed: (Long) -> Long,
    onSelect: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val fill = remember { Animatable(0f) }
    val strongFill = Palette.accentStrong.opacity(Emphasis.Medium)

    LaunchedEffect(silenceStart) {
        if (silenceStart == null) {
            fill.snapTo(0f)
            return@LaunchedEffect
        }

        val start = passed(silenceStart)

        fill.snapTo(start.toFloat() / duration)

        fill.animateTo(
            targetValue = 1f,
            animationSpec = tween(
                durationMillis = (duration - start).toInt(),
                easing = LinearEasing,
            ),
        )
    }

    Box(
        modifier = modifier
            .height(44.dp)
            .clip(CircleShape)
            .background(Palette.accent)
            .drawBehind {
                drawRect(
                    color = strongFill,
                    size = size.copy(width = size.width * fill.value),
                )
            }.clickable(onClick = onSelect),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = "話し終えた",
            color = Palette.backgroundTop,
            style = textFont(
                size = FontSize.Small,
                weight = FontWeight.Bold,
            ),
        )
    }
}

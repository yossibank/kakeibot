package com.yossibank.kakeibot.features.screens.entry.voice

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.opacity
import kotlin.math.abs

@Composable
fun EntryVoiceWave(
    levels: List<Float>,
    reach: Int,
    height: Dp,
    modifier: Modifier = Modifier,
) {
    Box(
        modifier = modifier.height(height),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(1.dp)
                .background(Palette.accent.opacity(Emphasis.Soft)),
        )

        Row(
            horizontalArrangement = Arrangement.spacedBy(GAP),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            for (offset in -reach..reach) {
                Bar(
                    level = level(
                        levels = levels,
                        distance = abs(offset),
                        reach = reach,
                    ),
                    height = height,
                )
            }
        }
    }
}

@Composable
private fun Bar(
    level: Float,
    height: Dp,
) {
    val animated by animateFloatAsState(
        targetValue = level,
        animationSpec = spring(dampingRatio = 0.65f),
        label = "level",
    )

    val glow = Palette.accent.opacity(Emphasis.Strong)

    Box(
        modifier = Modifier
            .width(BAR_WIDTH)
            .height(BAR_WIDTH + (height - BAR_WIDTH) * animated)
            .shadow(
                elevation = GLOW * animated,
                shape = CircleShape,
                ambientColor = glow,
                spotColor = glow,
            ).clip(CircleShape)
            .background(Brush.verticalGradient(listOf(Palette.accentStrong, Palette.accent))),
    )
}

private fun level(
    levels: List<Float>,
    distance: Int,
    reach: Int,
): Float {
    val level = levels.getOrElse(distance) { 0f }
    val fade = 1f - TAPER * distance / maxOf(reach, 1)
    return level * fade
}

private val BAR_WIDTH: Dp = 4.dp
private val GAP: Dp = 3.dp
private val GLOW: Dp = 6.dp
private const val TAPER = 0.6f

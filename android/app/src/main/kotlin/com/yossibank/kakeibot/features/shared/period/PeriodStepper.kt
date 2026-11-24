package com.yossibank.kakeibot.features.shared.period

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont

@Composable
fun PeriodStepper(
    title: String,
    onPrevious: () -> Unit,
    onNext: () -> Unit,
    modifier: Modifier = Modifier,
    caption: String? = null,
    canMoveForward: Boolean = true,
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        StepButton(
            rotation = 180f,
            isEnabled = true,
            onSelect = onPrevious,
        )

        Column(
            modifier = Modifier.weight(1f),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = title,
                color = Palette.accentStrong,
                style = displayFont(size = FontSize.Headline),
            )

            if (caption != null) {
                Text(
                    text = caption,
                    color = Palette.subtext,
                    style = textFont(style = FontTextStyle.Caption),
                )
            }
        }

        StepButton(
            rotation = 0f,
            isEnabled = canMoveForward,
            onSelect = onNext,
        )
    }
}

@Composable
private fun StepButton(
    rotation: Float,
    isEnabled: Boolean,
    onSelect: () -> Unit,
) {
    Box(
        modifier = Modifier
            .size(40.dp)
            .clip(CircleShape)
            .clickable(
                enabled = isEnabled,
                onClick = onSelect,
            ),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            painter = painterResource(R.drawable.ic_chevron_right),
            contentDescription = null,
            modifier = Modifier
                .size(24.dp)
                .rotate(rotation),
            tint = if (isEnabled) Palette.accent else Palette.accent.opacity(Emphasis.Muted),
        )
    }
}

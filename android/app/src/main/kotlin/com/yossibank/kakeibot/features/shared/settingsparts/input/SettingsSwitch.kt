package com.yossibank.kakeibot.features.shared.settingsparts.input

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont

@Composable
fun SettingsSwitch(
    title: String,
    detail: String,
    icon: Int,
    isOn: Boolean,
    onChange: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .card()
            .clickable { onChange(!isOn) }
            .padding(16.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            painter = painterResource(icon),
            contentDescription = null,
            modifier = Modifier.size(22.dp),
            tint = Palette.accent,
        )

        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(2.dp),
        ) {
            Text(
                text = title,
                color = Palette.text,
                style = textFont(style = FontTextStyle.Subheadline),
            )

            Text(
                text = detail,
                color = Palette.subtext,
                style = textFont(style = FontTextStyle.Caption),
            )
        }

        SwitchTrack(isOn = isOn)
    }
}

@Composable
private fun SwitchTrack(isOn: Boolean) {
    val track by animateColorAsState(
        targetValue = if (isOn) Palette.accent else Palette.accent.opacity(Emphasis.Soft),
        label = "switch-track",
    )

    val offset by animateDpAsState(
        targetValue = if (isOn) 20.dp else 0.dp,
        label = "switch-thumb",
    )

    Box(
        modifier = Modifier
            .width(48.dp)
            .height(28.dp)
            .clip(CircleShape)
            .background(track)
            .padding(2.dp),
    ) {
        Box(
            modifier = Modifier
                .offset(x = offset)
                .size(24.dp)
                .clip(CircleShape)
                .background(Palette.backgroundTop),
        )
    }
}

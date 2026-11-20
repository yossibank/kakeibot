package com.yossibank.kakeibot.features.shared.settingsparts

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont
import kotlinx.coroutines.delay

private const val NOTICE_MILLIS = 4_000L

@Composable
fun SettingsUndoNotice(
    message: String,
    icon: Int,
    onUndo: () -> Unit,
    onClose: () -> Unit,
    modifier: Modifier = Modifier,
) {
    LaunchedEffect(message) {
        delay(NOTICE_MILLIS)
        onClose()
    }

    val shape = RoundedCornerShape(20.dp)

    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(shape)
            .background(Palette.panel)
            .border(
                width = 1.dp,
                color = Palette.accent.opacity(Emphasis.Medium),
                shape = shape,
            ).padding(
                horizontal = 16.dp,
                vertical = 12.dp,
            ),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            painter = painterResource(icon),
            contentDescription = null,
            modifier = Modifier.size(20.dp),
            tint = Palette.accent,
        )

        Text(
            text = message,
            modifier = Modifier.weight(1f),
            color = Palette.text,
            style = textFont(
                size = FontSize.Small,
                weight = FontWeight.SemiBold,
            ),
        )

        Text(
            text = "取り消す",
            modifier = Modifier
                .clip(CircleShape)
                .border(
                    width = 1.dp,
                    color = Palette.accent.opacity(Emphasis.Muted),
                    shape = CircleShape,
                ).clickable {
                    onUndo()
                    onClose()
                }.padding(
                    horizontal = 12.dp,
                    vertical = 6.dp,
                ),
            color = Palette.accentStrong,
            style = textFont(
                size = FontSize.Small,
                weight = FontWeight.SemiBold,
            ),
        )
    }
}

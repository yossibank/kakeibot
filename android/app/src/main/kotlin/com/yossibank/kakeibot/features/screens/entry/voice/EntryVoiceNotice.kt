package com.yossibank.kakeibot.features.screens.entry.voice

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.LocalThemeStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.radius
import com.yossibank.kakeibot.designsystem.theme.textFont

@Composable
fun EntryVoiceNotice(
    notice: EntryVoiceFlow.Notice,
    onUndo: () -> Unit,
    onClose: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val shape = RoundedCornerShape(LocalThemeStyle.current.corner.radius(16.dp))
    val tint = if (notice.canUndo) Palette.accent else Palette.amber

    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(shape)
            .background(Palette.panel)
            .border(
                width = 1.dp,
                color = tint.opacity(Emphasis.Medium),
                shape = shape,
            ).clickable(onClick = onClose)
            .padding(
                horizontal = 16.dp,
                vertical = 12.dp,
            ),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            painter = painterResource(
                if (notice.canUndo) R.drawable.ic_check else R.drawable.ic_mic,
            ),
            contentDescription = null,
            modifier = Modifier.size(20.dp),
            tint = tint,
        )

        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(2.dp),
        ) {
            Text(
                text = notice.title,
                color = Palette.text,
                style = textFont(
                    size = FontSize.Small,
                    weight = FontWeight.SemiBold,
                ),
            )

            notice.message?.let { message ->
                Text(
                    text = message,
                    color = Palette.subtext,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                    style = textFont(size = FontSize.Caption),
                )
            }

            notice.hint?.let { hint ->
                Text(
                    text = hint,
                    color = Palette.hint,
                    style = textFont(size = FontSize.Caption),
                )
            }
        }

        if (notice.canUndo) {
            Box(
                modifier = Modifier
                    .height(32.dp)
                    .clip(CircleShape)
                    .border(
                        width = 1.dp,
                        color = Palette.accent.opacity(Emphasis.Medium),
                        shape = CircleShape,
                    ).clickable(onClick = onUndo)
                    .padding(horizontal = 12.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = "取り消す",
                    color = Palette.accent,
                    style = textFont(
                        size = FontSize.Caption,
                        weight = FontWeight.SemiBold,
                    ),
                )
            }
        }
    }
}

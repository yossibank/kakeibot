package com.yossibank.kakeibot.features.screens.entry.parts

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.designsystem.components.icon.IconTile
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.features.screens.entry.voice.EntryVoiceWave

@Composable
fun EntrySlipActiveRow(
    isActive: Boolean,
    modifier: Modifier = Modifier,
    content: @Composable RowScope.() -> Unit,
) {
    val fill = if (isActive) Palette.accent.opacity(Emphasis.Subtle) else Color.Transparent

    Row(
        modifier = modifier
            .fillMaxWidth()
            .background(fill),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .width(3.dp)
                .fillMaxHeight()
                .background(if (isActive) Palette.accent else Color.Transparent),
        )

        Row(
            modifier = Modifier
                .weight(1f)
                .padding(
                    start = 13.dp,
                    end = 12.dp,
                ),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            content()
        }
    }
}

@Composable
internal fun SymbolTile(icon: Int) {
    val shape = RoundedCornerShape(8.dp)

    Box(
        modifier = Modifier
            .size(30.dp)
            .background(
                color = Palette.accent.opacity(Emphasis.Subtle),
                shape = shape,
            ),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            painter = painterResource(icon),
            contentDescription = null,
            modifier = Modifier.size(18.dp),
            tint = Palette.accent,
        )
    }
}

@Composable
internal fun DayTile(day: Int) {
    val shape = RoundedCornerShape(8.dp)

    Box(
        modifier = Modifier
            .size(30.dp)
            .background(
                color = Palette.accent.opacity(Emphasis.Subtle),
                shape = shape,
            ).border(
                width = 1.dp,
                color = Palette.accent.opacity(Emphasis.Medium),
                shape = shape,
            ),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = day.toString(),
            color = Palette.accentStrong,
            style = displayFont(
                size = FontSize.Small,
                weight = FontWeight.Bold,
            ),
        )
    }
}

@Composable
internal fun Modifier.voiceUnderline(isOn: Boolean): Modifier {
    if (!isOn) {
        return this
    }

    val color = Palette.accent.opacity(Emphasis.Medium)

    return drawBehind {
        val y = size.height - 1.dp.toPx()

        drawLine(
            color = color,
            start = Offset(0f, y),
            end = Offset(size.width, y),
            strokeWidth = 1.dp.toPx(),
        )
    }
}

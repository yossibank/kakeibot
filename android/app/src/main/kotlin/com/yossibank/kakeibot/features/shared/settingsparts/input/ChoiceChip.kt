package com.yossibank.kakeibot.features.shared.settingsparts.input

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.designsystem.components.text.FittedText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont

@Composable
fun ChoiceChip(
    title: String,
    isSelected: Boolean,
    onSelect: () -> Unit,
    modifier: Modifier = Modifier,
    leading: @Composable () -> Unit = {},
) {
    val fill = if (isSelected) SolidColor(Palette.accent.opacity(Emphasis.Soft)) else Palette.card
    val rim = if (isSelected) Palette.accent else Palette.accent.opacity(Emphasis.Muted)

    Row(
        modifier = modifier
            .heightIn(min = 40.dp)
            .clip(CircleShape)
            .background(fill)
            .border(
                width = 1.dp,
                color = rim,
                shape = CircleShape,
            ).clickable(onClick = onSelect)
            .padding(
                horizontal = 12.dp,
                vertical = 6.dp,
            ),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        leading()

        FittedText(
            text = title,
            color = if (isSelected) Palette.accentStrong else Palette.text,
            style = textFont(
                size = FontSize.Small,
                weight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
            ),
        )
    }
}

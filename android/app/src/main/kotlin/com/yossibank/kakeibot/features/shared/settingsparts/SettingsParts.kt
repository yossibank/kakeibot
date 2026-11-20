package com.yossibank.kakeibot.features.shared.settingsparts

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
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
fun SettingsHeader(
    title: String,
    isRoot: Boolean,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    trailing: @Composable () -> Unit = {},
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(44.dp),
    ) {
        RoundIconButton(
            icon = if (isRoot) R.drawable.ic_close else R.drawable.ic_chevron_right,
            rotation = if (isRoot) 0f else 180f,
            onSelect = onBack,
            modifier = Modifier.align(Alignment.CenterStart),
        )

        Text(
            text = title,
            modifier = Modifier
                .align(Alignment.Center)
                .padding(horizontal = 56.dp),
            color = Palette.accentStrong,
            maxLines = 1,
            textAlign = TextAlign.Center,
            style = displayFont(size = FontSize.Headline),
        )

        Box(modifier = Modifier.align(Alignment.CenterEnd)) {
            trailing()
        }
    }
}

@Composable
fun RoundIconButton(
    icon: Int,
    onSelect: () -> Unit,
    modifier: Modifier = Modifier,
    rotation: Float = 0f,
) {
    Box(
        modifier = modifier
            .size(40.dp)
            .clip(CircleShape)
            .background(Palette.card)
            .border(
                width = 1.dp,
                color = Palette.accent.opacity(Emphasis.Muted),
                shape = CircleShape,
            ).clickable(onClick = onSelect),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            painter = painterResource(icon),
            contentDescription = null,
            modifier = Modifier
                .size(22.dp)
                .rotate(rotation),
            tint = Palette.accent,
        )
    }
}

@Composable
fun SettingsCaption(
    text: String,
    modifier: Modifier = Modifier,
) {
    Text(
        text = text,
        modifier = modifier.padding(horizontal = 8.dp),
        color = Palette.accent,
        style = textFont(
            style = FontTextStyle.Caption,
            weight = FontWeight.SemiBold,
        ),
    )
}

@Composable
fun SettingsRow(
    title: String,
    value: String,
    onSelect: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = 52.dp)
            .clickable(onClick = onSelect)
            .padding(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = title,
            modifier = Modifier.weight(1f),
            color = Palette.text,
            style = textFont(style = FontTextStyle.Body),
        )

        Text(
            text = value,
            color = Palette.subtext,
            maxLines = 1,
            style = textFont(style = FontTextStyle.Subheadline),
        )

        Icon(
            painter = painterResource(R.drawable.ic_chevron_right),
            contentDescription = null,
            modifier = Modifier.size(18.dp),
            tint = Palette.subtext,
        )
    }
}

@Composable
fun SettingsDivider(modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(1.dp)
            .background(Palette.line),
    )
}

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

        Text(
            text = title,
            color = if (isSelected) Palette.accentStrong else Palette.text,
            maxLines = 1,
            style = textFont(
                size = FontSize.Small,
                weight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
            ),
        )
    }
}

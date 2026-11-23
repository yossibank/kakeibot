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
import com.yossibank.kakeibot.designsystem.components.button.CircleIconButton
import com.yossibank.kakeibot.designsystem.components.surface.Hairline
import com.yossibank.kakeibot.designsystem.components.text.FittedText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Metrics
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

        FittedText(
            text = title,
            modifier = Modifier
                .align(Alignment.Center)
                .padding(horizontal = 56.dp),
            color = Palette.accentStrong,
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
    CircleIconButton(
        icon = icon,
        onClick = onSelect,
        modifier = modifier,
        rotation = rotation,
    )
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
            .heightIn(min = Metrics.rowMinHeight)
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

        FittedText(
            text = value,
            color = Palette.subtext,
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
    Hairline(modifier = modifier)
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

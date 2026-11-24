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
import com.yossibank.kakeibot.designsystem.components.input.PlaceholderTextField
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.features.screens.entry.model.EntryModel
import com.yossibank.kakeibot.features.screens.entry.model.isDateFromVoice
import com.yossibank.kakeibot.features.screens.entry.model.isMemoFromVoice
import com.yossibank.kakeibot.features.screens.entry.model.isWalletFromVoice
import com.yossibank.kakeibot.features.screens.entry.model.itemAdjustment
import com.yossibank.kakeibot.features.screens.entry.model.itemTotal
import com.yossibank.kakeibot.features.screens.entry.model.showsItems
import com.yossibank.kakeibot.features.screens.entry.voice.EntryVoiceFlow
import com.yossibank.kakeibot.features.screens.entry.voice.EntryVoiceWave

@Composable
fun EntrySlipMemoRow(
    model: EntryModel,
    onOpenItems: () -> Unit,
    onVoice: (() -> Unit)?,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(48.dp)
            .padding(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            painter = painterResource(R.drawable.ic_edit),
            contentDescription = null,
            modifier = Modifier.size(16.dp),
            tint = Palette.subtext,
        )

        PlaceholderTextField(
            value = model.state.form.memo,
            onChange = { memo -> model.state.update { copy(memo = memo) } },
            placeholder = "店名や買ったものをメモ",
            style = textFont(size = FontSize.Body),
            modifier = Modifier
                .weight(1f)
                .voiceUnderline(model.output.isMemoFromVoice),
        )

        if (model.output.showsItems && model.state.form.items.isNotEmpty()) {
            ItemButton(
                model = model,
                onOpen = onOpenItems,
            )
        }

        if (onVoice != null) {
            Box(
                modifier = Modifier
                    .size(32.dp)
                    .clip(CircleShape)
                    .border(
                        width = 1.dp,
                        color = Palette.accent.opacity(Emphasis.Medium),
                        shape = CircleShape,
                    ).clickable(onClick = onVoice),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    painter = painterResource(R.drawable.ic_mic),
                    contentDescription = null,
                    modifier = Modifier.size(18.dp),
                    tint = Palette.accent,
                )
            }
        }
    }
}

@Composable
private fun ItemButton(
    model: EntryModel,
    onOpen: () -> Unit,
) {
    val adjustment = model.output.itemAdjustment
    val tint = if (adjustment == 0L) Palette.accent else Palette.amber
    val fill = tint.opacity(Emphasis.Subtle)

    val style = textFont(
        size = FontSize.Caption,
        weight = FontWeight.SemiBold,
    )

    Row(
        modifier = Modifier
            .height(28.dp)
            .clip(CircleShape)
            .background(fill)
            .clickable(onClick = onOpen)
            .padding(horizontal = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = "品目 ${model.state.form.items.size}件",
            color = Palette.accentStrong,
            style = style,
        )

        Text(
            text = AmountText.text(model.output.itemTotal.toInt()),
            color = Palette.text,
            style = style,
        )

        if (adjustment != 0L) {
            Text(
                text = "差額 ${AmountText.text(adjustment.toInt())}",
                color = Palette.amber,
                style = style,
            )
        }
    }
}

package com.yossibank.kakeibot.designsystem.components.row

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont

@Composable
fun FeeChoiceRow(
    choices: List<Int>,
    selection: Int,
    onSelect: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        (listOf(0) + choices).forEach { amount ->
            val isSelected = amount == selection
            val fill = if (isSelected) Palette.accent.opacity(Emphasis.Soft) else Color.Transparent
            val rim = if (isSelected) Palette.accent else Palette.accent.opacity(Emphasis.Muted)

            Box(
                modifier = Modifier
                    .weight(1f)
                    .height(32.dp)
                    .clip(CircleShape)
                    .background(fill)
                    .border(
                        width = 1.dp,
                        color = rim,
                        shape = CircleShape,
                    ).clickable { onSelect(amount) },
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = if (amount == 0) "なし" else AmountText.text(amount),
                    color = if (isSelected) Palette.accentStrong else Palette.text,
                    maxLines = 1,
                    style = textFont(
                        size = FontSize.Caption,
                        weight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                    ),
                )
            }
        }
    }
}

object FeeChoiceRow {
    val defaultChoices: List<Int> = listOf(110, 220, 330, 440)
}

package com.yossibank.kakeibot.designsystem.components.input

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont

@Composable
fun <Value> SegmentSwitch(
    selection: Value,
    options: List<Pair<Value, String>>,
    onSelect: (Value) -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier
            .clip(CircleShape)
            .background(Palette.card)
            .border(
                width = 1.dp,
                color = Palette.accent.opacity(Emphasis.Muted),
                shape = CircleShape,
            ).padding(3.dp),
    ) {
        options.forEach { (value, title) ->
            val isSelected = value == selection
            val fill = if (isSelected) Palette.accent.opacity(Emphasis.Soft) else Color.Transparent

            Box(
                modifier = Modifier
                    .height(30.dp)
                    .clip(CircleShape)
                    .background(fill)
                    .clickable { onSelect(value) }
                    .padding(horizontal = 16.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = title,
                    color = if (isSelected) Palette.accentStrong else Palette.subtext,
                    style = textFont(
                        size = FontSize.Small,
                        weight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                    ),
                )
            }
        }
    }
}

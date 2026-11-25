package com.yossibank.kakeibot.designsystem.components.entry

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.designsystem.components.text.FittedText
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.textFont

@Composable
fun EntryRoute(
    source: String,
    destination: String,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(7.dp)
                .border(
                    width = 1.dp,
                    color = Palette.subtext,
                    shape = CircleShape,
                ),
        )

        FittedText(
            text = source,
            modifier = Modifier.weight(
                weight = 1f,
                fill = false,
            ),
            color = Palette.subtext,
            style = textFont(style = FontTextStyle.Caption),
        )

        Box(
            modifier = Modifier
                .width(20.dp)
                .height(1.dp)
                .background(Palette.outline),
        )

        Box(
            modifier = Modifier
                .size(7.dp)
                .background(
                    color = Palette.accent,
                    shape = CircleShape,
                ),
        )

        FittedText(
            text = destination,
            modifier = Modifier.weight(
                weight = 1f,
                fill = false,
            ),
            color = Palette.accentStrong,
            style = textFont(style = FontTextStyle.Caption),
        )
    }
}

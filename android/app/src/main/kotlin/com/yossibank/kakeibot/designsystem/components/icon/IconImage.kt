package com.yossibank.kakeibot.designsystem.components.icon

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.core.concepts.icon.Icon
import androidx.compose.material3.Icon as SymbolIcon

@Composable
fun IconImage(
    icon: Icon?,
    modifier: Modifier = Modifier,
    size: Dp = 22.dp,
) {
    val glyph = icon?.glyph

    Box(
        modifier = modifier.size(size * 1.4f),
        contentAlignment = Alignment.Center,
    ) {
        if (glyph != null) {
            SymbolIcon(
                painter = painterResource(glyph.symbol),
                contentDescription = null,
                modifier = Modifier.size(size * 1.15f),
                tint = LocalContentColor.current,
            )
        } else {
            val text = icon?.emoji ?: icon?.text ?: ""

            val scale = when {
                icon?.emoji != null || text.length <= 1 -> 1f
                text.length == 2 -> 0.7f
                else -> 0.55f
            }

            val fontSize = with(LocalDensity.current) {
                (size * scale).toSp()
            }

            Text(
                text = text,
                fontSize = fontSize,
                maxLines = 1,
            )
        }
    }
}

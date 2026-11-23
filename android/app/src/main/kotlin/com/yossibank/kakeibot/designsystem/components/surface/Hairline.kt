package com.yossibank.kakeibot.designsystem.components.surface

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.designsystem.theme.Palette

@Composable
fun Hairline(
    modifier: Modifier = Modifier,
    color: Color = Palette.line,
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(1.dp)
            .background(color),
    )
}

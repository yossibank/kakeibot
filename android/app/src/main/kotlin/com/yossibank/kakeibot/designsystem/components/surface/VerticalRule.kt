package com.yossibank.kakeibot.designsystem.components.surface

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.designsystem.theme.Palette

@Composable
fun VerticalRule(
    modifier: Modifier = Modifier,
    height: Dp = 28.dp,
) {
    Box(
        modifier = modifier
            .width(1.dp)
            .height(height)
            .background(Palette.line),
    )
}

package com.yossibank.kakeibot.features.shared.settingsparts.input

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.yossibank.kakeibot.designsystem.components.button.CircleIconButton

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

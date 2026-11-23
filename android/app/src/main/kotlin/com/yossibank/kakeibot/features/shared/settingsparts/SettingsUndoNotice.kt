package com.yossibank.kakeibot.features.shared.settingsparts

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.yossibank.kakeibot.designsystem.components.modal.UndoNotice

@Composable
fun SettingsUndoNotice(
    message: String,
    icon: Int,
    onUndo: () -> Unit,
    onClose: () -> Unit,
    modifier: Modifier = Modifier,
) {
    UndoNotice(
        title = message,
        icon = icon,
        modifier = modifier,
        onUndo = {
            onUndo()
            onClose()
        },
    )
}

package com.yossibank.kakeibot.features.shared.settingsparts

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.designsystem.theme.Metrics
import com.yossibank.kakeibot.designsystem.theme.Palette

@Composable
fun SettingsFrame(
    title: String,
    isRoot: Boolean,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    followsKeyboard: Boolean = false,
    trailing: @Composable () -> Unit = {},
    overlay: @Composable BoxScope.() -> Unit = {},
    content: @Composable ColumnScope.() -> Unit,
) {
    val keyboard = if (followsKeyboard) Modifier.imePadding() else Modifier

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(Palette.background)
            .pointerInput(Unit) {},
    ) {
        Column(
            modifier = Modifier
                .statusBarsPadding()
                .navigationBarsPadding()
                .then(keyboard)
                .padding(Metrics.screenPadding),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            SettingsHeader(
                title = title,
                isRoot = isRoot,
                onBack = onBack,
                trailing = trailing,
            )

            content()
        }

        overlay()
    }
}

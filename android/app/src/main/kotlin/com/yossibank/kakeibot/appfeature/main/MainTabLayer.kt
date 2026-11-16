package com.yossibank.kakeibot.appfeature.main

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.zIndex

@Composable
fun MainTabLayer(
    selection: MainTabSelection,
    value: MainTab,
    content: @Composable () -> Unit,
) {
    if (value !in selection.visited) {
        return
    }

    val isShown = selection.value == value

    Box(
        modifier = Modifier
            .fillMaxSize()
            .zIndex(if (isShown) 1f else 0f)
            .alpha(if (isShown) 1f else 0f)
            .pointerInput(Unit) {},
    ) {
        content()
    }
}

package com.yossibank.kakeibot.appfeature.main

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.zIndex
import com.yossibank.kakeibot.featuremodels.screens.main.MainModel

@Composable
fun MainTabLayer(
    model: MainModel,
    value: MainModel.Tab,
    content: @Composable () -> Unit,
) {
    if (value !in model.state.tabs.visited) {
        return
    }

    val isShown = model.state.tabs.current == value

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

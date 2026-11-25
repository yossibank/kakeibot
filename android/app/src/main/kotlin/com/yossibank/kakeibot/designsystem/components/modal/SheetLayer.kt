package com.yossibank.kakeibot.designsystem.components.modal

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier

@Composable
fun <Item : Any> SheetLayer(
    item: Item?,
    modifier: Modifier = Modifier,
    content: @Composable (Item) -> Unit,
) {
    var last by remember { mutableStateOf(item) }

    if (item != null) {
        last = item
    }

    AnimatedVisibility(
        visible = item != null,
        modifier = modifier,
        enter = slideInVertically { it },
        exit = slideOutVertically { it },
    ) {
        last?.let { content(it) }
    }
}

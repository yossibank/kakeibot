package com.yossibank.kakeibot.appfeature.main

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.zIndex
import com.yossibank.kakeibot.designsystem.components.navigation.FloatingTabBar

@Composable
fun MainTabBar(
    selection: MainTabSelection,
    onAdd: () -> Unit,
    modifier: Modifier = Modifier,
) {
    FloatingTabBar(
        selection = selection.value,
        items = tabItems,
        onSelect = selection::select,
        onAdd = onAdd,
        modifier = modifier.zIndex(2f),
    )
}

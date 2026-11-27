package com.yossibank.kakeibot.appfeature.main

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.zIndex
import com.yossibank.kakeibot.designsystem.components.navigation.FloatingTabBar
import com.yossibank.kakeibot.featuremodels.screens.main.MainModel

@Composable
fun MainTabBar(
    model: MainModel,
    onAdd: () -> Unit,
    modifier: Modifier = Modifier,
) {
    FloatingTabBar(
        selection = model.state.tabs.current,
        items = tabItems,
        onSelect = model.state::select,
        onAdd = onAdd,
        modifier = modifier.zIndex(2f),
    )
}

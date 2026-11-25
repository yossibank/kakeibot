package com.yossibank.kakeibot.appfeature.main

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.designsystem.components.navigation.FloatingTabBar
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.featuremodels.screens.main.MainModel

internal val tabItems: List<FloatingTabBar.Item<MainModel.Tab>> = listOf(
    FloatingTabBar.Item(
        title = MainModel.Tab.Home.title,
        icon = R.drawable.ic_tab_home,
        value = MainModel.Tab.Home,
    ),
    FloatingTabBar.Item(
        title = MainModel.Tab.Records.title,
        icon = R.drawable.ic_tab_records,
        value = MainModel.Tab.Records,
    ),
    FloatingTabBar.Item(
        title = MainModel.Tab.Review.title,
        icon = R.drawable.ic_tab_review,
        value = MainModel.Tab.Review,
    ),
    FloatingTabBar.Item(
        title = MainModel.Tab.Assets.title,
        icon = R.drawable.ic_tab_assets,
        value = MainModel.Tab.Assets,
    ),
)

@Composable
internal fun TabContent(content: @Composable () -> Unit) {
    Box(modifier = Modifier.fillMaxSize()) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .navigationBarsPadding()
                .padding(bottom = FloatingTabBar.clearance),
        ) {
            content()
        }

        Box(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .navigationBarsPadding()
                .height(FloatingTabBar.clearance + fadeReach)
                .background(
                    Brush.verticalGradient(
                        colors = listOf(Color.Transparent, Palette.backgroundBottom),
                    ),
                ),
        )
    }
}

private val fadeReach = 24.dp

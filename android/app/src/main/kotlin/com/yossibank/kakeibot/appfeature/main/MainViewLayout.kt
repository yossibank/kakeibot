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

enum class MainTab(
    val title: String,
) {
    Home("ホーム"),
    Records("記録"),
    Review("振り返り"),
    Assets("資産"),
}

internal val tabItems: List<FloatingTabBar.Item<MainTab>> = listOf(
    FloatingTabBar.Item(
        title = MainTab.Home.title,
        icon = R.drawable.ic_tab_home,
        value = MainTab.Home,
    ),
    FloatingTabBar.Item(
        title = MainTab.Records.title,
        icon = R.drawable.ic_tab_records,
        value = MainTab.Records,
    ),
    FloatingTabBar.Item(
        title = MainTab.Review.title,
        icon = R.drawable.ic_tab_review,
        value = MainTab.Review,
    ),
    FloatingTabBar.Item(
        title = MainTab.Assets.title,
        icon = R.drawable.ic_tab_assets,
        value = MainTab.Assets,
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

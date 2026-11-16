package com.yossibank.kakeibot.appfeature.main

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.store.database.AppDatabase

@Composable
fun MainView(
    database: AppDatabase,
    today: LocalDate,
) {
    val selection = rememberSaveable(saver = MainTabSelection.Saver) { MainTabSelection() }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Palette.background),
    ) {
        MainTab.entries.forEach { tab ->
            MainTabLayer(
                selection = selection,
                value = tab,
            ) {
                TabContent {
                    TabPlaceholder(tab = tab)
                }
            }
        }

        MainTabBar(
            selection = selection,
            onAdd = {},
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .navigationBarsPadding(),
        )
    }
}

@Composable
private fun TabPlaceholder(tab: MainTab) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = tab.title,
            color = Palette.subtext,
            style = displayFont(
                size = FontSize.Title,
                weight = FontWeight.Light,
            ),
        )
    }
}

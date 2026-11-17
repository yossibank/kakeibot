package com.yossibank.kakeibot.appfeature.main

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.zIndex
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.features.screens.entry.view.EntrySheet
import com.yossibank.kakeibot.features.screens.tabs.assets.view.AssetsView
import com.yossibank.kakeibot.features.screens.tabs.records.view.RecordsView
import com.yossibank.kakeibot.store.database.AppDatabase

@Composable
fun MainView(
    database: AppDatabase,
    today: LocalDate,
) {
    val selection = rememberSaveable(saver = MainTabSelection.Saver) { MainTabSelection() }
    var isEntryShown by rememberSaveable { mutableStateOf(false) }
    var editing by remember { mutableStateOf<Identifier<Entry>?>(null) }

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
                    if (tab == MainTab.Records) {
                        RecordsView(
                            database = database,
                            today = today,
                            onOpenEntry = { id ->
                                editing = id
                                isEntryShown = true
                            },
                        )
                    } else if (tab == MainTab.Assets) {
                        AssetsView(database = database)
                    } else {
                        TabPlaceholder(tab = tab)
                    }
                }
            }
        }

        MainTabBar(
            selection = selection,
            onAdd = {
                editing = null
                isEntryShown = true
            },
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .navigationBarsPadding(),
        )

        AnimatedVisibility(
            visible = isEntryShown,
            modifier = Modifier.zIndex(3f),
            enter = slideInVertically { it },
            exit = slideOutVertically { it },
        ) {
            EntrySheet(
                database = database,
                today = today,
                editing = editing,
                onClose = { isEntryShown = false },
            )
        }
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

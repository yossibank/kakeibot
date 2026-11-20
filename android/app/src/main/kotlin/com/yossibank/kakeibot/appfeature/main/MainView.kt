package com.yossibank.kakeibot.appfeature.main

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.Saver
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.zIndex
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.notification.PlannedNotification
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.features.screens.entry.view.EntrySheet
import com.yossibank.kakeibot.features.screens.settings.budgets.BudgetListView
import com.yossibank.kakeibot.features.screens.settings.menu.SettingsMenuSheet
import com.yossibank.kakeibot.features.screens.tabs.assets.view.AssetsView
import com.yossibank.kakeibot.features.screens.tabs.home.view.HomeView
import com.yossibank.kakeibot.features.screens.tabs.records.view.RecordsView
import com.yossibank.kakeibot.features.screens.tabs.review.view.ReviewView
import com.yossibank.kakeibot.store.database.AppDatabase

@Composable
fun MainView(
    database: AppDatabase,
    today: LocalDate,
    link: String?,
    onOpenLink: () -> Unit,
) {
    val selection = rememberSaveable(saver = MainTabSelection.Saver) { MainTabSelection() }
    var isEntryShown by rememberSaveable { mutableStateOf(false) }
    var editing by rememberSaveable(
        stateSaver = Saver<Identifier<Entry>?, String>(
            save = { it?.toString() },
            restore = { Identifier.parse(it) },
        ),
    ) { mutableStateOf(null) }
    var isBudgetShown by rememberSaveable { mutableStateOf(false) }
    var isSettingsShown by rememberSaveable { mutableStateOf(false) }
    var settingsRecurring by remember { mutableStateOf<Identifier<Recurring>?>(null) }
    var settingsRound by remember { mutableIntStateOf(0) }

    LaunchedEffect(link) {
        val route = link?.let { PlannedNotification.Route.of(link = it) } ?: return@LaunchedEffect

        onOpenLink()

        isEntryShown = false
        isBudgetShown = false
        isSettingsShown = false

        when (route) {
            is PlannedNotification.Route.Recurring -> {
                settingsRecurring = route.id
                settingsRound += 1
                isSettingsShown = true
            }

            is PlannedNotification.Route.Entry -> {
                editing = null
                isEntryShown = true
            }

            else -> {
                selection.select(MainTab.Home)
            }
        }
    }

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
                    when (tab) {
                        MainTab.Home -> {
                            HomeView(
                                database = database,
                                today = today,
                                onOpenBudget = { isBudgetShown = true },
                                onOpenEntry = { id ->
                                    editing = id
                                    isEntryShown = true
                                },
                                onOpenSettings = { isSettingsShown = true },
                            )
                        }

                        MainTab.Records -> {
                            RecordsView(
                                database = database,
                                today = today,
                                onOpenEntry = { id ->
                                    editing = id
                                    isEntryShown = true
                                },
                            )
                        }

                        MainTab.Review -> {
                            ReviewView(
                                database = database,
                                today = today,
                            )
                        }

                        MainTab.Assets -> {
                            AssetsView(database = database)
                        }
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

        AnimatedVisibility(
            visible = isSettingsShown,
            modifier = Modifier.zIndex(3f),
            enter = slideInVertically { it },
            exit = slideOutVertically { it },
        ) {
            key(settingsRound) {
                SettingsMenuSheet(
                    database = database,
                    today = today,
                    onClose = {
                        isSettingsShown = false
                        settingsRecurring = null
                    },
                    openRecurring = settingsRecurring,
                )
            }
        }

        AnimatedVisibility(
            visible = isBudgetShown,
            modifier = Modifier.zIndex(3f),
            enter = slideInVertically { it },
            exit = slideOutVertically { it },
        ) {
            BudgetListView(
                database = database,
                today = today,
                onBack = { isBudgetShown = false },
            )
        }
    }
}

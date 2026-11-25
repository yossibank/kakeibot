package com.yossibank.kakeibot.appfeature.main

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
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
import com.yossibank.kakeibot.featuremodels.shared.model.ObservationRound
import com.yossibank.kakeibot.features.screens.entry.view.EntrySheet
import com.yossibank.kakeibot.features.screens.settings.budgets.BudgetListView
import com.yossibank.kakeibot.features.screens.settings.menu.SettingsMenuSheet
import com.yossibank.kakeibot.features.screens.tabs.assets.view.AssetsView
import com.yossibank.kakeibot.features.screens.tabs.home.view.HomeView
import com.yossibank.kakeibot.features.screens.tabs.records.view.RecordsView
import com.yossibank.kakeibot.features.screens.tabs.review.view.ReviewView
import com.yossibank.kakeibot.features.shared.entrylist.LocalEntryList
import com.yossibank.kakeibot.features.shared.entrylist.rememberSharedEntryList
import com.yossibank.kakeibot.features.shared.observation.LocalObservationRound
import com.yossibank.kakeibot.store.database.AppDatabase

@Composable
fun MainView(
    database: AppDatabase,
    today: LocalDate,
    link: String?,
    onOpenLink: () -> Unit,
) {
    val selection = rememberSaveable(saver = MainTabSelection.Saver) { MainTabSelection() }
    var sheet by rememberSaveable(stateSaver = MainSheet.Saver) { mutableStateOf(null) }
    var round by remember { mutableIntStateOf(0) }

    val entryList = rememberSharedEntryList(database)
    val observation = remember { ObservationRound() }
    val openEntry: (Identifier<Entry>?) -> Unit = { sheet = MainSheet.Entry(editing = it) }

    LaunchedEffect(link) {
        val route = link?.let { PlannedNotification.Route.of(link = it) } ?: return@LaunchedEffect

        onOpenLink()

        sheet = null

        when (route) {
            is PlannedNotification.Route.Recurring -> {
                round += 1

                sheet = MainSheet.Settings(
                    recurring = route.id,
                    round = round,
                )
            }

            is PlannedNotification.Route.Entry -> {
                openEntry(null)
            }

            else -> {
                selection.select(MainTab.Home)
            }
        }
    }

    CompositionLocalProvider(
        LocalEntryList provides entryList,
        LocalObservationRound provides observation,
    ) {
        MainLayers(
            database = database,
            today = today,
            selection = selection,
            sheet = sheet,
            onOpen = { sheet = it },
        )
    }
}

@Composable
private fun MainLayers(
    database: AppDatabase,
    today: LocalDate,
    selection: MainTabSelection,
    sheet: MainSheet?,
    onOpen: (MainSheet?) -> Unit,
) {
    val openEntry: (Identifier<Entry>?) -> Unit = { onOpen(MainSheet.Entry(editing = it)) }

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
                                onOpenBudget = { onOpen(MainSheet.Budget) },
                                onOpenEntry = openEntry,
                                onOpenSettings = { onOpen(MainSheet.Settings()) },
                            )
                        }

                        MainTab.Records -> {
                            RecordsView(
                                database = database,
                                today = today,
                                onOpenEntry = openEntry,
                            )
                        }

                        MainTab.Review -> {
                            ReviewView(
                                database = database,
                                today = today,
                            )
                        }

                        MainTab.Assets -> {
                            AssetsView(
                                database = database,
                                today = today,
                            )
                        }
                    }
                }
            }
        }

        MainTabBar(
            selection = selection,
            onAdd = { openEntry(null) },
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .navigationBarsPadding(),
        )

        SheetLayer<MainSheet.Entry>(sheet = sheet) { entry ->
            EntrySheet(
                database = database,
                today = today,
                editing = entry.editing,
                onClose = { onOpen(null) },
            )
        }

        SheetLayer<MainSheet.Settings>(sheet = sheet) { settings ->
            key(settings.round) {
                SettingsMenuSheet(
                    database = database,
                    today = today,
                    onClose = { onOpen(null) },
                    openRecurring = settings.recurring,
                )
            }
        }

        SheetLayer<MainSheet.Budget>(sheet = sheet) {
            BudgetListView(
                database = database,
                today = today,
                onBack = { onOpen(null) },
            )
        }
    }
}

@Composable
private inline fun <reified Sheet : MainSheet> SheetLayer(
    sheet: MainSheet?,
    crossinline content: @Composable (Sheet) -> Unit,
) {
    val current = sheet as? Sheet
    var last by remember { mutableStateOf(current) }

    if (current != null) {
        last = current
    }

    AnimatedVisibility(
        visible = current != null,
        modifier = Modifier.zIndex(SHEET_LAYER),
        enter = slideInVertically { it },
        exit = slideOutVertically { it },
    ) {
        last?.let { content(it) }
    }
}

private const val SHEET_LAYER = 3f

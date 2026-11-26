package com.yossibank.kakeibot.appfeature.main

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.key
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.zIndex
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LifecycleEventEffect
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.notification.PlannedNotification
import com.yossibank.kakeibot.designsystem.components.modal.SheetLayer
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.featuremodels.screens.main.MainModel
import com.yossibank.kakeibot.featuremodels.shared.model.ForegroundReturn
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenParts
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenPartsShared
import com.yossibank.kakeibot.featuremodels.shared.model.perform
import com.yossibank.kakeibot.features.screens.entry.view.EntrySheet
import com.yossibank.kakeibot.features.screens.settings.budgets.BudgetListView
import com.yossibank.kakeibot.features.screens.settings.menu.SettingsMenuSheet
import com.yossibank.kakeibot.features.screens.tabs.assets.view.AssetsView
import com.yossibank.kakeibot.features.screens.tabs.home.view.HomeView
import com.yossibank.kakeibot.features.screens.tabs.records.view.RecordsView
import com.yossibank.kakeibot.features.screens.tabs.review.view.ReviewView
import com.yossibank.kakeibot.features.shared.observation.LocalObservationRound

@Composable
fun MainView(
    parts: ScreenParts,
    today: LocalDate,
    link: String?,
    onOpenLink: () -> Unit,
) {
    val model = rememberMainModel()
    val shared = rememberSharedParts(parts)

    SceneEffect(model)

    LaunchedEffect(link) {
        val route = link?.let { PlannedNotification.Route.of(link = it) } ?: return@LaunchedEffect

        onOpenLink()
        model.perform { it.open(route) }
    }

    CompositionLocalProvider(LocalObservationRound provides model.state.observation) {
        MainLayers(
            parts = shared,
            today = today,
            model = model,
        )
    }
}

@Composable
private fun SceneEffect(model: MainModel) {
    LifecycleEventEffect(Lifecycle.Event.ON_RESUME) {
        model.state.changeScene(to = ForegroundReturn.Phase.Active)
    }

    LifecycleEventEffect(Lifecycle.Event.ON_PAUSE) {
        model.state.changeScene(to = ForegroundReturn.Phase.Inactive)
    }

    LifecycleEventEffect(Lifecycle.Event.ON_STOP) {
        model.state.changeScene(to = ForegroundReturn.Phase.Background)
    }
}

@Composable
private fun rememberSharedParts(parts: ScreenParts): ScreenParts {
    val shared = remember(parts) { ScreenPartsShared(parts) }

    DisposableEffect(shared) {
        onDispose { shared.stop() }
    }

    return shared.parts
}

@Composable
private fun MainLayers(
    parts: ScreenParts,
    today: LocalDate,
    model: MainModel,
) {
    val sheet = model.state.sheet
    val close = { model.state.sheet = null }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Palette.background),
    ) {
        MainModel.Tab.entries.forEach { tab ->
            MainTabLayer(
                model = model,
                value = tab,
            ) {
                TabContent {
                    when (tab) {
                        MainModel.Tab.Home -> {
                            HomeView(
                                parts = parts,
                                today = today,
                                onOpenBudget = { model.state.sheet = MainModel.Sheet.Budget },
                                onOpenEntry = model::openEntry,
                                onAddEntry = { model.openEntry(editing = null) },
                                onOpenSettings = {
                                    model.state.sheet = MainModel.Sheet.Settings()
                                },
                            )
                        }

                        MainModel.Tab.Records -> {
                            RecordsView(
                                parts = parts,
                                today = today,
                                onOpenEntry = model::openEntry,
                            )
                        }

                        MainModel.Tab.Review -> {
                            ReviewView(
                                parts = parts,
                                today = today,
                            )
                        }

                        MainModel.Tab.Assets -> {
                            AssetsView(
                                parts = parts,
                                today = today,
                            )
                        }
                    }
                }
            }
        }

        MainTabBar(
            model = model,
            onAdd = { model.openEntry(editing = null) },
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .navigationBarsPadding(),
        )

        SheetLayer(
            item = sheet as? MainModel.Sheet.Entry,
            modifier = Modifier.zIndex(SHEET_LAYER),
        ) { entry ->
            EntrySheet(
                parts = parts,
                today = today,
                editing = entry.editing,
                date = entry.date,
                onClose = close,
            )
        }

        SheetLayer(
            item = sheet as? MainModel.Sheet.Settings,
            modifier = Modifier.zIndex(SHEET_LAYER),
        ) { settings ->
            key(settings.round) {
                SettingsMenuSheet(
                    parts = parts,
                    today = today,
                    onClose = close,
                    openRecurring = settings.recurring,
                )
            }
        }

        SheetLayer(
            item = sheet as? MainModel.Sheet.Budget,
            modifier = Modifier.zIndex(SHEET_LAYER),
        ) {
            BudgetListView(
                parts = parts,
                today = today,
                onBack = close,
            )
        }
    }
}

private const val SHEET_LAYER = 3f

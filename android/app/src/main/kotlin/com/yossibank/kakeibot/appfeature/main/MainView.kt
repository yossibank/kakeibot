package com.yossibank.kakeibot.appfeature.main

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.Saver
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.zIndex
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.features.screens.entry.view.EntrySheet
import com.yossibank.kakeibot.features.screens.settings.budgets.BudgetEditSheet
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
) {
    val selection = rememberSaveable(saver = MainTabSelection.Saver) { MainTabSelection() }
    var isEntryShown by rememberSaveable { mutableStateOf(false) }
    var editing by rememberSaveable(
        stateSaver = Saver<Identifier<Entry>?, String>(
            save = { it?.toString() },
            restore = { Identifier.parse(it) },
        ),
    ) { mutableStateOf(null) }
    var budgetTarget by remember { mutableStateOf<BudgetTarget?>(null) }
    var isSettingsShown by rememberSaveable { mutableStateOf(false) }

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
                                onEditBudget = { month, amount ->
                                    budgetTarget = BudgetTarget(
                                        month = month,
                                        amount = amount,
                                    )
                                },
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
            SettingsMenuSheet(
                database = database,
                today = today,
                onClose = { isSettingsShown = false },
            )
        }

        AnimatedVisibility(
            visible = budgetTarget != null,
            modifier = Modifier.zIndex(3f),
            enter = slideInVertically { it },
            exit = slideOutVertically { it },
        ) {
            val target = remember { budgetTarget }

            if (target != null) {
                BudgetEditSheet(
                    database = database,
                    month = target.month,
                    amount = target.amount,
                    onClose = { budgetTarget = null },
                )
            }
        }
    }
}

private data class BudgetTarget(
    val month: YearMonth,
    val amount: Int?,
)

package com.yossibank.kakeibot.features.screens.settings.menu

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.core.concepts.date.Weekday
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.setting.SettingsScreen
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.features.screens.settings.budgets.BudgetListView
import com.yossibank.kakeibot.features.screens.settings.period.MonthStartView
import com.yossibank.kakeibot.features.screens.settings.period.WeekStartView
import com.yossibank.kakeibot.features.screens.settings.period.title
import com.yossibank.kakeibot.features.screens.settings.recurrings.RecurringListView
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsCaption
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsDivider
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsHeader
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsHintButton
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsIntroCard
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsIntroNote
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsRow
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsScreenFlag
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.recurringUpdates
import com.yossibank.kakeibot.store.queries.methods.settingUpdates
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.monthStartDay
import com.yossibank.kakeibot.store.records.settingkeys.weekStart
import com.yossibank.kakeibot.store.writes.methods.setSetting
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.launch

private sealed interface Screen {
    data object Menu : Screen

    data object Budgets : Screen

    data object MonthStart : Screen

    data object WeekStart : Screen

    data object Recurrings : Screen
}

@Composable
fun SettingsMenuSheet(
    database: AppDatabase,
    today: LocalDate,
    onClose: () -> Unit,
    openRecurring: Identifier<Recurring>? = null,
) {
    var screen by remember {
        mutableStateOf(if (openRecurring != null) Screen.Recurrings else Screen.Menu)
    }

    val monthStartDay by remember(database) { database.settingUpdates(SettingKey.monthStartDay) }
        .collectAsState(initial = MonthStartDay.first)

    val weekStart by remember(database) { database.settingUpdates(SettingKey.weekStart) }
        .collectAsState(initial = Weekday.monday)

    val recurrings by remember(database) { database.recurringUpdates() }
        .collectAsState(initial = emptyList())

    val scope = rememberCoroutineScope()

    val monthStartHint = remember(database) {
        SettingsScreenFlag.closedHint(SettingsScreen.monthStartDay, database)
    }

    fun <Value> store(
        key: SettingKey<Value>,
        value: Value,
    ) {
        scope.launch {
            try {
                database.setSetting(
                    key = key,
                    to = value,
                )
            } catch (error: CancellationException) {
                throw error
            } catch (_: Exception) {
                return@launch
            }
        }
    }

    fun back() {
        when (screen) {
            Screen.Menu -> onClose()
            else -> screen = Screen.Menu
        }
    }

    BackHandler(onBack = ::back)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Palette.background)
            .pointerInput(Unit) {}
            .statusBarsPadding()
            .navigationBarsPadding()
            .imePadding()
            .padding(
                horizontal = 16.dp,
                vertical = 12.dp,
            ),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        when (screen) {
            Screen.Menu -> {
                SettingsHeader(
                    title = "設定",
                    isRoot = true,
                    onBack = ::back,
                )

                SettingsCaption(text = "予算と期間")

                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .card(),
                ) {
                    SettingsRow(
                        title = "予算",
                        value = "",
                        onSelect = { screen = Screen.Budgets },
                    )

                    SettingsDivider()

                    SettingsRow(
                        title = "固定費",
                        value = "${recurrings.size} 件",
                        onSelect = { screen = Screen.Recurrings },
                    )

                    SettingsDivider()

                    SettingsRow(
                        title = "月の始まり",
                        value = monthStartDay.title,
                        onSelect = { screen = Screen.MonthStart },
                    )

                    SettingsDivider()

                    SettingsRow(
                        title = "週の始まり",
                        value = weekStart.title,
                        onSelect = { screen = Screen.WeekStart },
                    )
                }
            }

            Screen.MonthStart -> {
                SettingsHeader(
                    title = "月の始まり",
                    isRoot = false,
                    onBack = ::back,
                ) {
                    SettingsHintButton(flag = monthStartHint)
                }

                SettingsIntroCard(
                    icon = R.drawable.ic_calendar,
                    headline = "給料日に合わせて" to "1 か月を数えられます",
                    flag = monthStartHint,
                    notes = listOf(
                        SettingsIntroNote(R.drawable.ic_chevron_right, "給料日から、次の給料日の前日までです"),
                        SettingsIntroNote(R.drawable.ic_calendar, "29〜31 日が無い月は、月末からです"),
                        SettingsIntroNote(R.drawable.ic_swap, "土日・祝日は、平日にずらせます"),
                    ),
                )

                MonthStartView(
                    selection = monthStartDay,
                    today = today,
                    onSelect = {
                        store(
                            key = SettingKey.monthStartDay,
                            value = it,
                        )
                    },
                )
            }

            Screen.WeekStart -> {
                SettingsHeader(
                    title = "週の始まり",
                    isRoot = false,
                    onBack = ::back,
                )

                WeekStartView(
                    selection = weekStart,
                    onSelect = {
                        store(
                            key = SettingKey.weekStart,
                            value = it,
                        )
                    },
                )
            }

            Screen.Budgets, Screen.Recurrings -> {}
        }
    }

    if (screen == Screen.Budgets) {
        BudgetListView(
            database = database,
            today = today,
            onBack = ::back,
        )
    }

    if (screen == Screen.Recurrings) {
        RecurringListView(
            database = database,
            today = today,
            onBack = ::back,
            opening = openRecurring,
        )
    }
}

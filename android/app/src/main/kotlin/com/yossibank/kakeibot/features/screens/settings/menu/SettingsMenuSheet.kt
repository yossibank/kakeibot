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
import androidx.compose.runtime.LaunchedEffect
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
import com.yossibank.kakeibot.features.screens.settings.monthstartday.MonthStartDayView
import com.yossibank.kakeibot.features.screens.settings.monthstartday.title
import com.yossibank.kakeibot.features.screens.settings.recurring.RecurringListView
import com.yossibank.kakeibot.features.shared.settingsparts.hint.SettingsHintButton
import com.yossibank.kakeibot.features.shared.settingsparts.hint.SettingsIntroCard
import com.yossibank.kakeibot.features.shared.settingsparts.hint.SettingsIntroNote
import com.yossibank.kakeibot.features.shared.settingsparts.hint.SettingsScreenFlag
import com.yossibank.kakeibot.features.shared.settingsparts.input.SettingsRow
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsCaption
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsDivider
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsFrame
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsHeader
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.recurringUpdates
import com.yossibank.kakeibot.store.queries.methods.settingUpdates
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.monthStartDay
import com.yossibank.kakeibot.store.records.settingkeys.weekStart
import com.yossibank.kakeibot.store.writes.methods.setSetting
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.launch

private enum class Screen(
    val title: String,
) {
    Menu("設定"),
    Budgets("設定"),
    MonthStart("月の始まり"),
    WeekStart("週の始まり"),
    Recurrings("設定"),
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

    val model = remember(database) { SettingsMenuModel(database = database) }
    val scope = rememberCoroutineScope()

    LaunchedEffect(model) {
        model.observe()
    }

    val monthStartHint = remember(database) {
        SettingsScreenFlag.closedHint(SettingsScreen.monthStartDay, database)
    }

    fun back() {
        when (screen) {
            Screen.Menu -> onClose()
            else -> screen = Screen.Menu
        }
    }

    BackHandler(onBack = ::back)

    SettingsFrame(
        title = screen.title,
        isRoot = screen == Screen.Menu,
        onBack = ::back,
        followsKeyboard = true,
        trailing = {
            if (screen == Screen.MonthStart) {
                SettingsHintButton(flag = monthStartHint)
            }
        },
    ) {
        when (screen) {
            Screen.Menu -> {
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
                        value = "${model.recurringCount} 件",
                        onSelect = { screen = Screen.Recurrings },
                    )

                    SettingsDivider()

                    SettingsRow(
                        title = "月の始まり",
                        value = model.monthStartDay.title,
                        onSelect = { screen = Screen.MonthStart },
                    )

                    SettingsDivider()

                    SettingsRow(
                        title = "週の始まり",
                        value = model.weekStart.title,
                        onSelect = { screen = Screen.WeekStart },
                    )
                }
            }

            Screen.MonthStart -> {
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

                MonthStartDayView(
                    selection = model.monthStartDay,
                    today = today,
                    onSelect = { day ->
                        scope.launch {
                            model.store(
                                key = SettingKey.monthStartDay,
                                value = day,
                            )
                        }
                    },
                )
            }

            Screen.WeekStart -> {
                SettingsMenuWeekStart(
                    selection = model.weekStart,
                    onSelect = { weekday ->
                        scope.launch {
                            model.store(
                                key = SettingKey.weekStart,
                                value = weekday,
                            )
                        }
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

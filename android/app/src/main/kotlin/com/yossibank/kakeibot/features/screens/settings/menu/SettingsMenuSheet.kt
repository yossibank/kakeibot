package com.yossibank.kakeibot.features.screens.settings.menu

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.pointer.pointerInput
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.core.concepts.date.Weekday
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.designsystem.components.notice.NoticeBanner
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.featuremodels.screens.settings.menu.SettingsMenuModel
import com.yossibank.kakeibot.featuremodels.screens.settings.menu.SettingsMenuModel.Screen
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenParts
import com.yossibank.kakeibot.featuremodels.shared.model.perform
import com.yossibank.kakeibot.features.screens.settings.budgets.BudgetListView
import com.yossibank.kakeibot.features.screens.settings.monthstartday.MonthStartDayView
import com.yossibank.kakeibot.features.screens.settings.monthstartday.title
import com.yossibank.kakeibot.features.screens.settings.recurring.RecurringListView
import com.yossibank.kakeibot.features.shared.settingsparts.hint.SettingsHintButton
import com.yossibank.kakeibot.features.shared.settingsparts.hint.SettingsIntroCard
import com.yossibank.kakeibot.features.shared.settingsparts.hint.SettingsIntroNote
import com.yossibank.kakeibot.features.shared.settingsparts.input.SettingsRow
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsCaption
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsDivider
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsFrame
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsHeader
import kotlinx.coroutines.CancellationException

@Composable
fun SettingsMenuSheet(
    parts: ScreenParts,
    today: LocalDate,
    onClose: () -> Unit,
    openRecurring: Identifier<Recurring>? = null,
) {
    val model = remember(parts) {
        SettingsMenuModel(
            parts = parts,
            screen = if (openRecurring != null) Screen.Recurrings else Screen.Menu,
        )
    }

    val screen = model.state.screen

    LaunchedEffect(model) {
        model.observe()
    }

    model.state.task.Timer()

    fun back() {
        when (screen) {
            Screen.Menu -> onClose()
            else -> model.state.open(Screen.Menu)
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
                SettingsHintButton(
                    fold = model.input.monthStartHint,
                    model = model,
                )
            }
        },
    ) {
        if (model.state.task.message.isNotEmpty()) {
            NoticeBanner(
                message = model.state.task.message,
                onClose = model.state.task::clear,
            )
        }

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
                        onSelect = { model.state.open(Screen.Budgets) },
                    )

                    SettingsDivider()

                    SettingsRow(
                        title = "固定費",
                        value = "${model.input.recurringCount} 件",
                        onSelect = { model.state.open(Screen.Recurrings) },
                    )

                    SettingsDivider()

                    SettingsRow(
                        title = "月の始まり",
                        value = model.input.monthStartDay.title,
                        onSelect = { model.state.open(Screen.MonthStart) },
                    )

                    SettingsDivider()

                    SettingsRow(
                        title = "週の始まり",
                        value = model.input.weekStart.title,
                        onSelect = { model.state.open(Screen.WeekStart) },
                    )
                }
            }

            Screen.MonthStart -> {
                SettingsIntroCard(
                    icon = R.drawable.ic_calendar,
                    headline = "給料日に合わせて" to "1 か月を数えられます",
                    fold = model.input.monthStartHint,
                    model = model,
                    notes = listOf(
                        SettingsIntroNote(R.drawable.ic_chevron_right, "給料日から、次の給料日の前日までです"),
                        SettingsIntroNote(R.drawable.ic_calendar, "29〜31 日が無い月は、月末からです"),
                        SettingsIntroNote(R.drawable.ic_swap, "土日・祝日は、平日にずらせます"),
                    ),
                )

                MonthStartDayView(
                    selection = model.input.monthStartDay,
                    today = today,
                    onSelect = { day -> model.perform { it.choose(monthStartDay = day) } },
                )
            }

            Screen.WeekStart -> {
                SettingsMenuWeekStart(
                    selection = model.input.weekStart,
                    onSelect = { weekday -> model.perform { it.choose(weekStart = weekday) } },
                )
            }

            Screen.Budgets, Screen.Recurrings -> {}
        }
    }

    if (screen == Screen.Budgets) {
        BudgetListView(
            parts = parts,
            today = today,
            onBack = ::back,
        )
    }

    if (screen == Screen.Recurrings) {
        RecurringListView(
            parts = parts,
            today = today,
            onBack = ::back,
            opening = openRecurring,
        )
    }
}

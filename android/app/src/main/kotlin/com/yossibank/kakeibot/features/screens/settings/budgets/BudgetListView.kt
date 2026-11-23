package com.yossibank.kakeibot.features.screens.settings.budgets

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.budget.BudgetUsage
import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.setting.SettingsScreen
import com.yossibank.kakeibot.designsystem.components.budget.BudgetUsageBar
import com.yossibank.kakeibot.designsystem.components.budget.carryoverText
import com.yossibank.kakeibot.designsystem.components.budget.remainingText
import com.yossibank.kakeibot.designsystem.components.budget.tint
import com.yossibank.kakeibot.designsystem.components.icon.IconTile
import com.yossibank.kakeibot.designsystem.components.modal.UndoNoticeState
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.components.text.FittedText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Metrics
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.features.shared.entrylist.rememberEntryList
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsCaption
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsDivider
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsFrame
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsHeader
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsHintButton
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsIntroCard
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsIntroNote
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsScreenFlag
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsSwitch
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsUndoNotice
import com.yossibank.kakeibot.store.database.AppDatabase
import kotlinx.coroutines.launch

@Composable
fun BudgetListView(
    database: AppDatabase,
    today: LocalDate,
    onBack: () -> Unit,
) {
    val entryList = rememberEntryList(database)

    val model = remember(database, entryList) {
        BudgetListModel(
            database = database,
            entryList = entryList,
            today = today,
        )
    }

    SideEffect {
        model.today = today
    }

    val hint =
        remember(database) { SettingsScreenFlag.closedHint(SettingsScreen.budgets, database) }
    val scope = rememberCoroutineScope()

    val cleared = remember { UndoNoticeState<BudgetListModel.Cleared>() }
    val resetFrom = remember { UndoNoticeState<YearMonth>() }

    LaunchedEffect(model) {
        model.observe()
    }

    cleared.Timer()
    resetFrom.Timer()

    BackHandler(onBack = onBack)

    SettingsFrame(
        title = "予算",
        isRoot = false,
        onBack = onBack,
        trailing = { SettingsHintButton(flag = hint) },
        overlay = {
            BudgetNotices(
                model = model,
                cleared = cleared,
                resetFrom = resetFrom,
                modifier = Modifier.align(Alignment.BottomCenter),
            )

            BudgetKeypadDrawer(
                model = model,
                onCleared = cleared::show,
            )
        },
    ) {
        SettingsIntroCard(
            icon = R.drawable.ic_glyph_budget,
            headline = "月に使う額を" to "カテゴリ別に決めます",
            flag = hint,
            notes = listOf(
                SettingsIntroNote(R.drawable.ic_calendar, "変えた額はこの月から使います"),
                SettingsIntroNote(R.drawable.ic_repeat, "前の月の額はそのまま残ります"),
            ),
        )

        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(bottom = 96.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            BudgetTotalCard(
                model = model,
                onEdit = { model.startEditing(BudgetListModel.Target.Total) },
                onReset = {
                    scope.launch { model.resetCarryover()?.let(resetFrom::show) }
                },
            )

            SettingsSwitch(
                title = "残りを繰り越す",
                detail = "使いすぎた分は、次の月の予算から引きます",
                icon = R.drawable.ic_repeat,
                isOn = model.isCarryoverOn,
                onChange = { isOn ->
                    scope.launch { model.setCarryover(isOn) }
                },
            )

            if (model.budgeted.isNotEmpty()) {
                Section(
                    title = "カテゴリごと",
                    note = model.categoriesNote,
                ) {
                    RowsCard(categories = model.budgeted) { category ->
                        BudgetCategoryRow(
                            model = model,
                            category = category,
                        )
                    }
                }
            }

            if (model.unbudgeted.isNotEmpty()) {
                Section(
                    title = "予算なし",
                    note = model.unbudgetedNote,
                ) {
                    RowsCard(categories = model.unbudgeted) { category ->
                        BudgetPlainRow(
                            model = model,
                            category = category,
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun BudgetNotices(
    model: BudgetListModel,
    cleared: UndoNoticeState<BudgetListModel.Cleared>,
    resetFrom: UndoNoticeState<YearMonth>,
    modifier: Modifier = Modifier,
) {
    val scope = rememberCoroutineScope()

    Column(
        modifier = modifier
            .navigationBarsPadding()
            .padding(
                horizontal = 16.dp,
                vertical = 8.dp,
            ),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        cleared.current?.let { current ->
            SettingsUndoNotice(
                message = "${current.target.title}をなくしました",
                icon = R.drawable.ic_trash,
                onUndo = { scope.launch { model.restore(current) } },
                onClose = cleared::dismiss,
            )
        }

        resetFrom.current?.let { start ->
            SettingsUndoNotice(
                message = "繰越を 0 に戻しました",
                icon = R.drawable.ic_repeat,
                onUndo = { scope.launch { model.restoreCarryover(from = start) } },
                onClose = resetFrom::dismiss,
            )
        }

        if (model.message.isNotEmpty() && model.editing == null) {
            Text(
                text = model.message,
                modifier = Modifier
                    .fillMaxWidth()
                    .card()
                    .padding(12.dp),
                color = Palette.rose,
                style = textFont(style = FontTextStyle.Caption),
            )
        }
    }
}

@Composable
private fun Section(
    title: String,
    note: String,
    content: @Composable () -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            SettingsCaption(
                text = title,
                modifier = Modifier.weight(1f),
            )

            Text(
                text = note,
                modifier = Modifier.padding(end = 8.dp),
                color = Palette.subtext,
                style = textFont(style = FontTextStyle.Caption2),
            )
        }

        content()
    }
}

@Composable
private fun RowsCard(
    categories: List<EntryCategory>,
    row: @Composable (EntryCategory) -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .card()
            .padding(horizontal = 16.dp),
    ) {
        categories.forEachIndexed { index, category ->
            if (index > 0) {
                SettingsDivider()
            }

            row(category)
        }
    }
}

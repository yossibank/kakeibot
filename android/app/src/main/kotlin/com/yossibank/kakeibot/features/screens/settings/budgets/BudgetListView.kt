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
import com.yossibank.kakeibot.designsystem.components.budget.BudgetUsageBar
import com.yossibank.kakeibot.designsystem.components.budget.carryoverText
import com.yossibank.kakeibot.designsystem.components.budget.remainingText
import com.yossibank.kakeibot.designsystem.components.budget.tint
import com.yossibank.kakeibot.designsystem.components.icon.IconTile
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.components.text.FittedText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Metrics
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.screens.settings.budgets.BudgetListModel
import com.yossibank.kakeibot.featuremodels.screens.settings.budgets.categoriesNote
import com.yossibank.kakeibot.featuremodels.screens.settings.budgets.unbudgetedNote
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenParts
import com.yossibank.kakeibot.featuremodels.shared.model.perform
import com.yossibank.kakeibot.features.shared.settingsparts.board.SettingsUndoNotice
import com.yossibank.kakeibot.features.shared.settingsparts.hint.SettingsHintButton
import com.yossibank.kakeibot.features.shared.settingsparts.hint.SettingsIntroCard
import com.yossibank.kakeibot.features.shared.settingsparts.hint.SettingsIntroNote
import com.yossibank.kakeibot.features.shared.settingsparts.input.SettingsSwitch
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsCaption
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsDivider
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsFrame
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsHeader

@Composable
fun BudgetListView(
    parts: ScreenParts,
    today: LocalDate,
    onBack: () -> Unit,
) {
    val model = remember(parts) {
        BudgetListModel(
            parts = parts,
            today = today,
        )
    }

    SideEffect {
        model.setToday(today)
    }

    LaunchedEffect(model) {
        model.observe()
    }

    BackHandler(onBack = onBack)

    SettingsFrame(
        title = "予算",
        isRoot = false,
        onBack = onBack,
        trailing = {
            SettingsHintButton(
                fold = model.input.hint,
                model = model,
            )
        },
        overlay = {
            BudgetNotices(
                model = model,
                modifier = Modifier.align(Alignment.BottomCenter),
            )

            BudgetKeypadDrawer(model = model)
        },
    ) {
        BudgetIntro(model = model)

        BudgetContent(
            model = model,
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState()),
        )
    }
}

@Composable
private fun BudgetIntro(model: BudgetListModel) {
    SettingsIntroCard(
        icon = R.drawable.ic_glyph_budget,
        headline = "月に使う額を" to "カテゴリ別に決めます",
        fold = model.input.hint,
        model = model,
        notes = listOf(
            SettingsIntroNote(R.drawable.ic_calendar, "変えた額はこの月から使います"),
            SettingsIntroNote(R.drawable.ic_repeat, "前の月の額はそのまま残ります"),
        ),
    )
}

@Composable
private fun BudgetContent(
    model: BudgetListModel,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier.padding(bottom = 96.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        BudgetTotalCard(
            model = model,
            onEdit = { model.startEditing(BudgetListModel.Target.Total) },
            onReset = { model.perform { it.resetCarryover() } },
        )

        SettingsSwitch(
            title = "残りを繰り越す",
            detail = "使いすぎた分は、次の月の予算から引きます",
            icon = R.drawable.ic_repeat,
            isOn = model.output.isCarryoverOn,
            onChange = { isOn -> model.perform { it.setCarryover(isOn) } },
        )

        if (model.output.budgeted.isNotEmpty()) {
            BudgetedSection(model = model)
        }

        if (model.output.unbudgeted.isNotEmpty()) {
            UnbudgetedSection(model = model)
        }
    }
}

@Composable
private fun BudgetedSection(model: BudgetListModel) {
    Section(
        title = "カテゴリごと",
        note = model.output.categoriesNote,
    ) {
        RowsCard(categories = model.output.budgeted) { category ->
            BudgetCategoryRow(
                model = model,
                category = category,
            )
        }
    }
}

@Composable
private fun UnbudgetedSection(model: BudgetListModel) {
    Section(
        title = "予算なし",
        note = model.output.unbudgetedNote,
    ) {
        RowsCard(categories = model.output.unbudgeted) { category ->
            BudgetPlainRow(
                model = model,
                category = category,
            )
        }
    }
}

@Composable
private fun BudgetNotices(
    model: BudgetListModel,
    modifier: Modifier = Modifier,
) {
    val cleared = model.state.notices.cleared
    val resetFrom = model.state.notices.resetFrom

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
                onUndo = { model.perform { it.restore(current) } },
                onClose = cleared::dismiss,
            )
        }

        resetFrom.current?.let { start ->
            SettingsUndoNotice(
                message = "繰越を 0 に戻しました",
                icon = R.drawable.ic_repeat,
                onUndo = { model.perform { it.restoreCarryover(from = start) } },
                onClose = resetFrom::dismiss,
            )
        }

        if (model.state.notices.error.message.isNotEmpty() &&
            model.state.presented.editing == null
        ) {
            Text(
                text = model.state.notices.error.message,
                modifier = Modifier
                    .fillMaxWidth()
                    .card()
                    .clickable(onClick = model.state.notices.error::clear)
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

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
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Metrics
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont
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
    val model = remember(database) { BudgetListModel(database = database) }
    val hint =
        remember(database) { SettingsScreenFlag.closedHint(SettingsScreen.budgets, database) }
    val scope = rememberCoroutineScope()

    val cleared = remember { UndoNoticeState<BudgetListModel.Cleared>() }
    val resetFrom = remember { UndoNoticeState<YearMonth>() }

    LaunchedEffect(model, today) {
        model.observe(today = today)
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
            TotalCard(
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
                    note = "合計 ${AmountText.text(amount = model.categoriesTotal)}",
                ) {
                    RowsCard(categories = model.budgeted) { category ->
                        CategoryRow(
                            model = model,
                            category = category,
                        )
                    }
                }
            }

            if (model.unbudgeted.isNotEmpty()) {
                Section(
                    title = "予算なし",
                    note = "${model.unbudgeted.size} カテゴリ",
                ) {
                    RowsCard(categories = model.unbudgeted) { category ->
                        PlainRow(
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
private fun TotalCard(
    model: BudgetListModel,
    onEdit: () -> Unit,
    onReset: () -> Unit,
) {
    val usage = model.usage(categoryId = null)

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .card()
            .clickable(onClick = onEdit)
            .padding(vertical = 20.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Column(
            verticalArrangement = Arrangement.spacedBy(4.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = "月全体",
                color = Palette.accent,
                style = textFont(style = FontTextStyle.Caption),
            )

            Text(
                text = "${model.month?.month ?: ""}月（${model.periodText}）から使う額",
                color = Palette.subtext,
                maxLines = 1,
                style = textFont(style = FontTextStyle.Caption),
            )
        }

        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            AmountValue(
                amount = model.totalAmount,
                size = FontSize.LargeTitle,
                weight = FontWeight.Bold,
            )

            EditMark()
        }

        AnimatedVisibility(visible = model.isCarryoverOn && usage != null) {
            if (usage != null) {
                Row(
                    modifier = Modifier.padding(horizontal = 16.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        text = usage.carryoverText,
                        color = Palette.subtext,
                        maxLines = 1,
                        style = textFont(style = FontTextStyle.Caption),
                    )

                    if (usage.carryover != 0L) {
                        Text(
                            text = "0 に戻す",
                            modifier = Modifier
                                .clip(CircleShape)
                                .clickable(onClick = onReset)
                                .card()
                                .padding(
                                    horizontal = 10.dp,
                                    vertical = 4.dp,
                                ),
                            color = Palette.accentStrong,
                            style = textFont(
                                size = FontSize.Caption,
                                weight = FontWeight.SemiBold,
                            ),
                        )
                    }
                }
            }
        }

        if (usage != null) {
            UsageLine(
                usage = usage,
                modifier = Modifier.padding(
                    start = 24.dp,
                    top = 4.dp,
                    end = 24.dp,
                ),
            )
        }

        if (model.recurringExpense > 0) {
            Row(
                modifier = Modifier.padding(
                    start = 16.dp,
                    top = 4.dp,
                    end = 16.dp,
                ),
                horizontalArrangement = Arrangement.spacedBy(4.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(
                    painter = painterResource(R.drawable.ic_repeat),
                    contentDescription = null,
                    modifier = Modifier.size(14.dp),
                    tint = Palette.accent,
                )

                Text(
                    text = model.recurringText,
                    color = Palette.accent,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    style = textFont(style = FontTextStyle.Caption2),
                )
            }
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

@Composable
private fun CategoryRow(
    model: BudgetListModel,
    category: EntryCategory,
) {
    val usage = model.usage(categoryId = category.id)
    val spent = model.spent(categoryId = category.id)

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = Metrics.rowMinHeight)
            .clickable { model.startEditing(BudgetListModel.Target.Category(category)) }
            .padding(vertical = 12.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Row(
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconTile(
                icon = model.icon(category),
                size = 28.dp,
            )

            Text(
                text = category.name,
                modifier = Modifier.weight(1f),
                color = Palette.text,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                style = textFont(style = FontTextStyle.Subheadline),
            )

            AmountValue(
                amount = model.amount(categoryId = category.id),
                size = FontSize.Body,
            )

            EditMark()
        }

        if (usage != null) {
            UsageLine(
                usage = usage,
                modifier = Modifier.padding(start = 40.dp),
            )
        } else if (spent > 0) {
            SpentText(
                spent = spent,
                modifier = Modifier.padding(start = 40.dp),
            )
        }
    }
}

@Composable
private fun PlainRow(
    model: BudgetListModel,
    category: EntryCategory,
) {
    val spent = model.spent(categoryId = category.id)

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 48.dp)
            .clickable { model.startEditing(BudgetListModel.Target.Category(category)) }
            .padding(vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        IconTile(
            icon = model.icon(category),
            size = 28.dp,
        )

        Text(
            text = category.name,
            modifier = Modifier.weight(1f),
            color = Palette.text,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            style = textFont(style = FontTextStyle.Footnote),
        )

        if (spent > 0) {
            SpentText(spent = spent)
        }

        Icon(
            painter = painterResource(R.drawable.ic_add),
            contentDescription = null,
            modifier = Modifier.size(16.dp),
            tint = Palette.hint,
        )
    }
}

@Composable
private fun UsageLine(
    usage: BudgetUsage,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        BudgetUsageBar(usage = usage)

        Row {
            SpentText(
                spent = usage.spent,
                modifier = Modifier.weight(1f),
            )

            Text(
                text = usage.remainingText,
                color = usage.tint,
                maxLines = 1,
                style = textFont(style = FontTextStyle.Caption2),
            )
        }
    }
}

@Composable
private fun SpentText(
    spent: Long,
    modifier: Modifier = Modifier,
) {
    Text(
        text = "使った額 ${AmountText.text(amount = spent.toInt())}",
        modifier = modifier,
        color = Palette.subtext,
        maxLines = 1,
        style = textFont(style = FontTextStyle.Caption2),
    )
}

@Composable
private fun AmountValue(
    amount: Int?,
    size: FontSize,
    weight: FontWeight = FontWeight.Normal,
) {
    if (amount != null) {
        AmountText(
            amount = amount,
            style = displayFont(
                size = size,
                weight = weight,
            ),
            color = Palette.accentStrong,
        )
    } else {
        Text(
            text = "なし",
            color = Palette.hint,
            style = displayFont(
                size = size,
                weight = weight,
            ),
        )
    }
}

@Composable
private fun EditMark() {
    Box(
        modifier = Modifier
            .size(20.dp)
            .clip(CircleShape)
            .border(
                width = 1.dp,
                color = Palette.accent.opacity(Emphasis.Muted),
                shape = CircleShape,
            ),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            painter = painterResource(R.drawable.ic_edit),
            contentDescription = null,
            modifier = Modifier.size(12.dp),
            tint = Palette.accent,
        )
    }
}

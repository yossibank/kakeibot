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
import com.yossibank.kakeibot.featuremodels.screens.settings.budgets.BudgetListModel
import com.yossibank.kakeibot.featuremodels.shared.amount.AmountText
import com.yossibank.kakeibot.features.shared.entrylist.rememberEntryList
import com.yossibank.kakeibot.features.shared.settingsparts.board.SettingsUndoNotice
import com.yossibank.kakeibot.features.shared.settingsparts.hint.SettingsHintButton
import com.yossibank.kakeibot.features.shared.settingsparts.hint.SettingsIntroCard
import com.yossibank.kakeibot.features.shared.settingsparts.hint.SettingsIntroNote
import com.yossibank.kakeibot.features.shared.settingsparts.input.SettingsSwitch
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsCaption
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsDivider
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsFrame
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsHeader
import com.yossibank.kakeibot.store.database.AppDatabase
import kotlinx.coroutines.launch

@Composable
internal fun BudgetCategoryRow(
    model: BudgetListModel,
    category: EntryCategory,
) {
    val usage = model.output.usage(categoryId = category.id)
    val spent = model.output.spent(categoryId = category.id)

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
                icon = model.output.icon(category),
                size = 28.dp,
            )

            FittedText(
                text = category.name,
                modifier = Modifier.weight(1f),
                color = Palette.text,
                style = textFont(style = FontTextStyle.Subheadline),
            )

            AmountValue(
                amount = model.output.amount(categoryId = category.id),
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
internal fun BudgetPlainRow(
    model: BudgetListModel,
    category: EntryCategory,
) {
    val spent = model.output.spent(categoryId = category.id)

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
            icon = model.output.icon(category),
            size = 28.dp,
        )

        FittedText(
            text = category.name,
            modifier = Modifier.weight(1f),
            color = Palette.text,
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
internal fun UsageLine(
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

            FittedText(
                text = usage.remainingText,
                color = usage.tint,
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
    FittedText(
        text = "使った額 ${AmountText.text(amount = spent.toInt())}",
        modifier = modifier,
        color = Palette.subtext,
        style = textFont(style = FontTextStyle.Caption2),
    )
}

@Composable
internal fun AmountValue(
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
internal fun EditMark() {
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

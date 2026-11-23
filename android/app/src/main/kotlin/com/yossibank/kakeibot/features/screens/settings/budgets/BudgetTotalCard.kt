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
internal fun BudgetTotalCard(
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

            FittedText(
                text = "${model.month?.month ?: ""}月（${model.periodText}）から使う額",
                color = Palette.subtext,
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
                    FittedText(
                        text = usage.carryoverText,
                        color = Palette.subtext,
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

                FittedText(
                    text = model.recurringText,
                    color = Palette.accent,
                    style = textFont(style = FontTextStyle.Caption2),
                )
            }
        }
    }
}

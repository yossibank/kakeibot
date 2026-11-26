package com.yossibank.kakeibot.features.screens.tabs.home.view

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.budget.BudgetUsage
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.designsystem.components.budget.budgetText
import com.yossibank.kakeibot.designsystem.components.dial.HalfDial
import com.yossibank.kakeibot.designsystem.components.entry.EntryRow
import com.yossibank.kakeibot.designsystem.components.notice.noticeBanner
import com.yossibank.kakeibot.designsystem.components.surface.Hairline
import com.yossibank.kakeibot.designsystem.components.surface.VerticalRule
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.screens.tabs.home.model.HomeModel
import com.yossibank.kakeibot.featuremodels.shared.amount.clamped
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenParts
import com.yossibank.kakeibot.features.shared.entrylist.EntryItemRow
import com.yossibank.kakeibot.features.shared.notice.TabNoticeRound
import com.yossibank.kakeibot.features.shared.observation.rememberObservationRound
import com.yossibank.kakeibot.features.shared.placeholder.PlaceholderEmpty
import com.yossibank.kakeibot.features.shared.placeholder.PlaceholderLoadFailed
import com.yossibank.kakeibot.features.shared.settingsparts.input.RoundIconButton
import kotlin.math.abs

@Composable
fun HomeView(
    parts: ScreenParts,
    today: LocalDate,
    onOpenBudget: () -> Unit,
    onOpenEntry: (Identifier<Entry>) -> Unit,
    onAddEntry: () -> Unit,
    onOpenSettings: () -> Unit,
) {
    val round = rememberObservationRound()

    val model = remember(parts, round) {
        HomeModel(
            parts = parts,
            today = today,
            round = round,
        )
    }

    SideEffect {
        model.setToday(today)
    }

    LaunchedEffect(model) {
        model.observe()
    }

    model.state.task.Timer()
    TabNoticeRound(model.state.task)

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(
            start = 16.dp,
            top = 12.dp,
            end = 16.dp,
            bottom = 24.dp,
        ),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        item(key = "title") {
            Row(
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.Bottom,
            ) {
                Text(
                    text = model.output.month?.let { "${it.month}月" } ?: "",
                    modifier = Modifier.alignByBaseline(),
                    color = Palette.accentStrong,
                    style = displayFont(size = FontSize.Headline),
                )

                Text(
                    text = model.output.periodText,
                    modifier = Modifier
                        .alignByBaseline()
                        .weight(1f),
                    color = Palette.subtext,
                    style = textFont(style = FontTextStyle.Caption),
                )

                RoundIconButton(
                    icon = R.drawable.ic_settings,
                    onSelect = onOpenSettings,
                )
            }
        }

        noticeBanner(task = model.state.task)

        item(key = "budget") {
            BudgetCard(
                model = model,
                onOpenBudget = onOpenBudget,
            )
        }

        item(key = "recent") {
            RecentCard(
                model = model,
                onOpenEntry = onOpenEntry,
                onAddEntry = onAddEntry,
            )
        }
    }
}

@Composable
private fun BudgetCard(
    model: HomeModel,
    onOpenBudget: () -> Unit,
) {
    val overview = model.input.overview
    val usage = model.output.usage

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .card()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Dial(
            usage = usage,
            monthExpense = overview?.monthExpense ?: 0,
            isFailed = model.state.isListFailed,
        )

        Row(
            modifier = Modifier
                .clickable(onClick = onOpenBudget)
                .padding(
                    horizontal = 12.dp,
                    vertical = 4.dp,
                ),
            horizontalArrangement = Arrangement.spacedBy(4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = usage?.budgetText ?: "予算を決めると、あといくら使えるかが出ます",
                color = if (usage == null) Palette.accent else Palette.subtext,
                style = textFont(style = FontTextStyle.Subheadline),
            )

            Icon(
                painter = painterResource(R.drawable.ic_chevron_right),
                contentDescription = null,
                modifier = Modifier.size(18.dp),
                tint = if (usage == null) Palette.accent else Palette.subtext,
            )
        }

        Hairline()

        Row(verticalAlignment = Alignment.CenterVertically) {
            Stat(
                title = "今日の支出",
                amount = overview?.todayExpense ?: 0,
                type = Entry.Kind.expense,
                isFailed = model.state.isListFailed,
                modifier = Modifier.weight(1f),
            )

            VerticalRule()

            Stat(
                title = model.output.middleTitle,
                amount = model.output.middleAmount,
                type = Entry.Kind.expense,
                isFailed = model.state.isListFailed,
                modifier = Modifier.weight(1f),
            )

            VerticalRule()

            Stat(
                title = "今月の収入",
                amount = overview?.monthIncome ?: 0,
                type = Entry.Kind.income,
                isFailed = model.state.isListFailed,
                modifier = Modifier.weight(1f),
            )
        }
    }
}

@Composable
private fun Dial(
    usage: BudgetUsage?,
    monthExpense: Long,
    isFailed: Boolean,
) {
    val isOver = usage?.isOver ?: false
    val color = if (isOver) Palette.rose else Palette.accentStrong

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp),
        contentAlignment = Alignment.BottomCenter,
    ) {
        HalfDial(
            progress = if (isFailed) 0.0 else usage?.progress ?: 0.0,
            color = if (isOver) Palette.rose else Palette.accent,
        )

        Column(
            modifier = Modifier.padding(horizontal = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = when {
                    usage == null -> "今月の支出"
                    isOver -> "予算オーバー"
                    else -> "今月あといくら"
                },
                color = Palette.accent,
                style = textFont(style = FontTextStyle.Caption),
            )

            if (isFailed) {
                UnknownAmount(
                    style = displayFont(
                        size = FontSize.Display,
                        weight = FontWeight.Bold,
                    ),
                )
            } else {
                AmountText(
                    amount = (usage?.let { abs(it.remaining) } ?: monthExpense).clamped,
                    style = displayFont(
                        size = FontSize.Display,
                        weight = FontWeight.Bold,
                    ),
                    color = color,
                )
            }
        }
    }
}

@Composable
private fun Stat(
    title: String,
    amount: Long,
    type: Entry.Kind,
    isFailed: Boolean,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(2.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = title,
            color = Palette.subtext,
            style = textFont(style = FontTextStyle.Caption),
        )

        if (isFailed) {
            UnknownAmount(style = displayFont(size = FontSize.Body))
        } else {
            AmountText(
                amount = amount.clamped,
                style = displayFont(size = FontSize.Body),
                type = type,
            )
        }
    }
}

@Composable
private fun UnknownAmount(style: TextStyle) {
    Text(
        text = "—",
        color = Palette.subtext,
        style = style,
    )
}

@Composable
private fun RecentCard(
    model: HomeModel,
    onOpenEntry: (Identifier<Entry>) -> Unit,
    onAddEntry: () -> Unit,
) {
    val rows = model.output.recentRows

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .card()
            .padding(horizontal = 16.dp)
            .padding(
                top = 12.dp,
                bottom = 4.dp,
            ),
    ) {
        Text(
            text = "最近の記録",
            modifier = Modifier.padding(bottom = 8.dp),
            color = Palette.accent,
            style = textFont(
                style = FontTextStyle.Caption,
                weight = FontWeight.SemiBold,
            ),
        )

        if (model.state.isListFailed) {
            return@Column PlaceholderLoadFailed(onRetry = model::retry)
        }

        if (model.output.showsNoRecords) {
            PlaceholderEmpty(
                icon = R.drawable.ic_edit,
                text = "まだ記録がありません",
                onRecord = onAddEntry,
            )
        }

        rows.forEach { row ->
            Hairline()

            EntryItemRow(
                item = row,
                onOpen = { onOpenEntry(row.id) },
            )
        }
    }
}

package com.yossibank.kakeibot.features.screens.settings.recurring

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.billShiftTitles
import com.yossibank.kakeibot.core.concepts.recurring.billText
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.designsystem.components.icon.IconTile
import com.yossibank.kakeibot.designsystem.components.input.SegmentSwitch
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Metrics
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.RecurringEditModel
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.RecurringPanel
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.RecurringText
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.billDates
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.billRecurring
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.categories
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.isCardBill
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.select
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.walletTitle
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.wallets
import com.yossibank.kakeibot.featuremodels.shared.entrylist.EntryText
import com.yossibank.kakeibot.features.shared.settingsparts.input.ChoiceChip
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsDivider

@Composable
fun RecurringQuickCard(
    model: RecurringEditModel,
    onOpen: (RecurringPanel) -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .card()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Section(title = "金額") {
            AmountButton(
                model = model,
                onSelect = {
                    val isCardBill = model.output.isCardBill
                    onOpen(if (isCardBill) RecurringPanel.Closing else RecurringPanel.Amount)
                },
            )
        }

        if (model.state.form.type != Entry.Kind.transfer) {
            SettingsDivider()

            Section(title = "カテゴリ") {
                Chips {
                    model.output.categories.forEach { category ->
                        ChoiceChip(
                            title = category.name,
                            isSelected = category.id == model.state.form.categoryId,
                            onSelect = { model.select(category = category.id) },
                        ) {
                            IconTile(
                                icon = model.output.icon(of = category.iconId),
                                size = 24.dp,
                            )
                        }
                    }
                }
            }
        }

        SettingsDivider()

        Section(title = model.output.walletTitle) {
            WalletChips(
                model = model,
                selection = model.state.form.walletId,
                onSelect = { model.state.select(wallet = it) },
            )

            if (model.output.billRecurring != null) {
                BillShiftChips(model = model)
            }
        }

        if (model.state.form.type == Entry.Kind.transfer) {
            SettingsDivider()

            Section(title = EntryText.destinationTitle) {
                WalletChips(
                    model = model,
                    selection = model.state.form.toWalletId,
                    onSelect = { id -> model.state.update { copy(toWalletId = id) } },
                )
            }
        }

        SettingsDivider()

        Schedule(model = model)
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun DayGrid(
    selection: Int?,
    onSelect: (Int) -> Unit,
) {
    FlowRow(
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        MonthStartDay.allDays.forEach { day ->
            ChoiceChip(
                title = if (day.isLastDay) "末日" else "${day.day}",
                isSelected = day.day == selection,
                onSelect = { onSelect(day.day) },
                modifier = Modifier.widthIn(min = 40.dp),
            )
        }
    }
}

@Composable
private fun Section(
    title: String,
    content: @Composable () -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(
            text = title,
            color = Palette.accent,
            style = textFont(
                style = FontTextStyle.Caption,
                weight = FontWeight.SemiBold,
            ),
        )

        content()
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun Chips(content: @Composable () -> Unit) {
    FlowRow(
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        content()
    }
}

@Composable
private fun AmountButton(
    model: RecurringEditModel,
    onSelect: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = Metrics.rowMinHeight)
            .clickable(onClick = onSelect),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (model.output.isCardBill) {
            Text(
                text = "カードの利用分",
                modifier = Modifier.weight(1f),
                color = Palette.accentStrong,
                style = displayFont(size = FontSize.Headline),
            )
        } else {
            AmountText(
                amount = model.output.amount,
                modifier = Modifier.weight(1f),
                style = displayFont(
                    size = FontSize.Title,
                    weight = FontWeight.Bold,
                ),
                color = if (model.output.amount > 0) Palette.accentStrong else Palette.hint,
            )
        }

        Icon(
            painter = painterResource(R.drawable.ic_edit),
            contentDescription = null,
            modifier = Modifier.size(18.dp),
            tint = Palette.accent,
        )
    }
}

@Composable
private fun WalletChips(
    model: RecurringEditModel,
    selection: Identifier<Wallet>?,
    onSelect: (Identifier<Wallet>) -> Unit,
) {
    Chips {
        model.output.wallets.forEach { wallet ->
            ChoiceChip(
                title = wallet.name,
                isSelected = wallet.id == selection,
                onSelect = { onSelect(wallet.id) },
            ) {
                IconTile(
                    icon = model.output.icon(of = wallet.iconId),
                    size = 24.dp,
                )
            }
        }
    }
}

@Composable
private fun BillShiftChips(model: RecurringEditModel) {
    val dates = model.output.billDates

    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(
            text = "カードの請求",
            color = Palette.subtext,
            style = textFont(style = FontTextStyle.Caption),
        )

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Recurring.billShiftTitles.forEachIndexed { index, title ->
                val date = dates.getOrNull(index)

                ChoiceChip(
                    title = date?.let { "$title・${Recurring.billText(paidOn = it)}" } ?: title,
                    isSelected = model.state.form.billShift == index,
                    onSelect = { model.state.update { copy(billShift = index) } },
                )
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun Schedule(model: RecurringEditModel) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = 44.dp)
                .clickable { model.state.isScheduleOpen = !model.state.isScheduleOpen },
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = "繰り返し",
                modifier = Modifier.weight(1f),
                color = Palette.accent,
                style = textFont(
                    style = FontTextStyle.Caption,
                    weight = FontWeight.SemiBold,
                ),
            )

            Text(
                text = RecurringText.schedule(
                    frequency = model.state.form.frequency,
                    month = model.state.form.month,
                    day = model.state.form.day,
                ),
                color = Palette.accentStrong,
                style = textFont(style = FontTextStyle.Footnote),
            )

            Icon(
                painter = painterResource(R.drawable.ic_chevron_right),
                contentDescription = null,
                modifier = Modifier
                    .padding(start = 4.dp)
                    .size(16.dp)
                    .rotate(if (model.state.isScheduleOpen) 270f else 90f),
                tint = Palette.accentStrong,
            )
        }

        if (model.state.isScheduleOpen) {
            SegmentSwitch(
                selection = model.state.form.frequency,
                options = frequencies,
                onSelect = { frequency -> model.state.update { copy(frequency = frequency) } },
                modifier = Modifier.fillMaxWidth(),
            )

            if (model.state.form.frequency == Recurring.Frequency.yearly) {
                FlowRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    (1..12).forEach { month ->
                        ChoiceChip(
                            title = "$month 月",
                            isSelected = model.state.form.month == month,
                            onSelect = { model.state.update { copy(month = month) } },
                            modifier = Modifier.widthIn(min = 64.dp),
                        )
                    }
                }
            }

            DayGrid(
                selection = model.state.form.day,
                onSelect = { day -> model.state.update { copy(day = day) } },
            )
        }
    }
}

private val frequencies = listOf(
    Recurring.Frequency.monthly to "毎月",
    Recurring.Frequency.yearly to "毎年",
)

package com.yossibank.kakeibot.features.screens.entry.parts

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.Weekday
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.designsystem.components.date.MonthCalendar
import com.yossibank.kakeibot.designsystem.components.date.shortName
import com.yossibank.kakeibot.designsystem.components.icon.IconTile
import com.yossibank.kakeibot.designsystem.components.input.Keypad
import com.yossibank.kakeibot.designsystem.components.row.FeeChoiceRow
import com.yossibank.kakeibot.designsystem.components.tag.TagLine
import com.yossibank.kakeibot.designsystem.components.tag.TagLineItem
import com.yossibank.kakeibot.designsystem.components.text.FittedText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.LocalThemeStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.radius
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.features.screens.entry.model.EntryModel
import com.yossibank.kakeibot.features.screens.entry.model.apply
import com.yossibank.kakeibot.features.screens.entry.model.applyRecent
import com.yossibank.kakeibot.features.screens.entry.model.applyTransfer
import com.yossibank.kakeibot.features.screens.entry.model.categoryText
import com.yossibank.kakeibot.features.screens.entry.model.dateText
import com.yossibank.kakeibot.features.screens.entry.model.expressionText
import com.yossibank.kakeibot.features.screens.entry.model.feeChoices
import com.yossibank.kakeibot.features.screens.entry.model.newTemplateDraft
import com.yossibank.kakeibot.features.screens.entry.model.routeText
import com.yossibank.kakeibot.features.screens.entry.model.showsItems
import com.yossibank.kakeibot.features.screens.entry.model.tags
import com.yossibank.kakeibot.features.screens.entry.model.walletTitle
import com.yossibank.kakeibot.features.shared.entrylist.EntryText
import com.yossibank.kakeibot.core.concepts.icon.Icon as EntryIcon

@Composable
fun EntryDeck(
    model: EntryModel,
    onOpenItems: () -> Unit,
    onSaveTemplate: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(28.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            DeckTitle(
                text = when (model.state.field) {
                    EntryModel.Field.Category -> "カテゴリを選ぶ"
                    EntryModel.Field.Wallet -> "${model.output.walletTitle}を選ぶ"
                    EntryModel.Field.ToWallet -> "振替先を選ぶ"
                    EntryModel.Field.Date -> "日付を選ぶ"
                    EntryModel.Field.Amount -> "金額を入力"
                    EntryModel.Field.Fee -> "手数料を入力"
                    EntryModel.Field.Transfer -> "振替元と振替先"
                },
            )

            Spacer(modifier = Modifier.weight(1f))

            if (model.state.field == EntryModel.Field.Amount && model.output.showsItems) {
                ItemPill(onOpen = onOpenItems)
            }
        }

        Box(modifier = Modifier.weight(1f)) {
            when (model.state.field) {
                EntryModel.Field.Category -> CategoryArea(
                    model = model,
                    onSaveTemplate = onSaveTemplate,
                )

                EntryModel.Field.Wallet -> WalletList(
                    model = model,
                    selection = model.state.form.walletId,
                    onSelect = model.state::select,
                )

                EntryModel.Field.ToWallet -> WalletList(
                    model = model,
                    selection = model.state.form.toWalletId,
                    onSelect = model.state::selectDestination,
                )

                EntryModel.Field.Date -> DateCalendar(model = model)

                EntryModel.Field.Amount -> AmountKeypad(model = model)

                EntryModel.Field.Transfer -> EntryTransferArea(model = model)

                EntryModel.Field.Fee -> Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    FeeChoiceRow(
                        choices = model.output.feeChoices,
                        selection = model.output.fee,
                        onSelect = model.state::setFee,
                    )

                    Box(modifier = Modifier.weight(1f)) {
                        AmountKeypad(model = model)
                    }
                }
            }
        }
    }
}

@Composable
private fun ItemPill(onOpen: () -> Unit) {
    Row(
        modifier = Modifier
            .height(28.dp)
            .clip(CircleShape)
            .background(Palette.accent.opacity(Emphasis.Subtle))
            .border(
                width = 1.dp,
                color = Palette.accent.opacity(Emphasis.Medium),
                shape = CircleShape,
            ).clickable(onClick = onOpen)
            .padding(
                start = 4.dp,
                end = 12.dp,
            ),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(20.dp)
                .clip(CircleShape)
                .background(Palette.accent),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                painter = painterResource(R.drawable.ic_plus),
                contentDescription = null,
                modifier = Modifier.size(14.dp),
                tint = Palette.backgroundTop,
            )
        }

        Text(
            text = "品目に分ける",
            color = Palette.accent,
            style = textFont(
                size = FontSize.Caption,
                weight = FontWeight.Bold,
            ),
        )
    }
}

@Composable
private fun DeckTitle(text: String) {
    Text(
        text = text,
        color = Palette.subtext,
        style = textFont(
            size = FontSize.Caption,
            weight = FontWeight.SemiBold,
        ),
    )
}

@Composable
private fun AmountKeypad(model: EntryModel) {
    BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
        val spacing = 8.dp * (KEY_ROWS - 1)
        val height = ((maxHeight - spacing) / KEY_ROWS).coerceIn(minKeyHeight, maxKeyHeight)

        Keypad(
            calculator = model.output.activeCalculator,
            onKey = model.state::press,
            keyHeight = height,
        )
    }
}

@Composable
private fun CategoryArea(
    model: EntryModel,
    onSaveTemplate: () -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        CategoryGrid(
            model = model,
            modifier = Modifier.weight(1f),
        )

        val tags = model.output.tags

        if (tags.isNotEmpty()) {
            TagLine(
                tags = tags.map { TagLineItem(id = it.id, name = it.name) },
                selection = model.state.form.tagId,
                onSelect = model.state::toggleTag,
            )
        }

        if (model.output.amount > 0) {
            SaveTemplateChip(onSelect = onSaveTemplate)
        }
    }
}

@Composable
private fun SaveTemplateChip(onSelect: () -> Unit) {
    val rim = Palette.accent.opacity(Emphasis.Medium)

    Row(
        modifier = Modifier
            .height(32.dp)
            .clip(CircleShape)
            .drawBehind {
                drawRoundRect(
                    color = rim,
                    cornerRadius = CornerRadius(size.height / 2),
                    style = Stroke(
                        width = 1.dp.toPx(),
                        pathEffect = PathEffect.dashPathEffect(
                            floatArrayOf(4.dp.toPx(), 3.dp.toPx()),
                        ),
                    ),
                )
            }.clickable(onClick = onSelect)
            .padding(horizontal = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            painter = painterResource(R.drawable.ic_plus),
            contentDescription = null,
            modifier = Modifier.size(14.dp),
            tint = Palette.accent,
        )

        Text(
            text = "今の入力を保存",
            color = Palette.accent,
            style = textFont(
                size = FontSize.Caption,
                weight = FontWeight.SemiBold,
            ),
        )
    }
}

@Composable
private fun DateCalendar(model: EntryModel) {
    MonthCalendar(
        selection = model.state.form.date,
        today = model.state.today,
        onSelect = model.state::select,
    )
}

private const val KEY_ROWS = 5

private val minKeyHeight: Dp = 36.dp

private val maxKeyHeight: Dp = 72.dp

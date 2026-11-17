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
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
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
import com.yossibank.kakeibot.designsystem.components.date.shortName
import com.yossibank.kakeibot.designsystem.components.icon.IconTile
import com.yossibank.kakeibot.designsystem.components.input.Keypad
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.LocalThemeStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.radius
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.features.screens.entry.model.EntryModel
import com.yossibank.kakeibot.core.concepts.icon.Icon as EntryIcon

@Composable
fun EntryDeck(
    model: EntryModel,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        DeckTitle(
            text = when (model.field) {
                EntryModel.Field.Category -> "カテゴリを選ぶ"
                EntryModel.Field.Wallet -> "${model.walletTitle}を選ぶ"
                EntryModel.Field.ToWallet -> "振替先を選ぶ"
                EntryModel.Field.Date -> "日付を選ぶ"
                EntryModel.Field.Amount -> "金額を入力"
            },
        )

        Box(modifier = Modifier.weight(1f)) {
            when (model.field) {
                EntryModel.Field.Category -> CategoryGrid(model = model)

                EntryModel.Field.Wallet -> WalletList(
                    model = model,
                    selection = model.walletId,
                    onSelect = model::select,
                )

                EntryModel.Field.ToWallet -> WalletList(
                    model = model,
                    selection = model.toWalletId,
                    onSelect = model::selectDestination,
                )

                EntryModel.Field.Date -> DateCalendar(model = model)

                EntryModel.Field.Amount -> AmountKeypad(model = model)
            }
        }
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
            calculator = model.calculator,
            onKey = model::press,
            keyHeight = height,
        )
    }
}

@Composable
private fun CategoryGrid(model: EntryModel) {
    LazyVerticalGrid(
        columns = GridCells.Fixed(4),
        modifier = Modifier.fillMaxSize(),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        items(
            items = model.categories,
            key = { it.id.toString() },
        ) { category ->
            ChoiceCell(
                icon = model.icon(of = category.iconId),
                name = category.name,
                isSelected = category.id == model.categoryId,
                onSelect = { model.select(category) },
            )
        }
    }
}

@Composable
private fun WalletList(
    model: EntryModel,
    selection: Identifier<Wallet>?,
    onSelect: (Wallet) -> Unit,
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        items(
            items = model.wallets,
            key = { it.id.toString() },
        ) { wallet ->
            val isSelected = wallet.id == selection

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .choice(isSelected = isSelected)
                    .clickable { onSelect(wallet) }
                    .padding(
                        horizontal = 12.dp,
                        vertical = 8.dp,
                    ),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                IconTile(
                    icon = model.icon(of = wallet.iconId),
                    size = 36.dp,
                )

                Text(
                    text = wallet.name,
                    modifier = Modifier.weight(1f),
                    color = Palette.text,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    style = textFont(
                        size = FontSize.Body,
                        weight = FontWeight.Medium,
                    ),
                )

                if (isSelected) {
                    Icon(
                        painter = painterResource(R.drawable.ic_check),
                        contentDescription = null,
                        modifier = Modifier.size(20.dp),
                        tint = Palette.accent,
                    )
                }
            }
        }
    }
}

@Composable
private fun ChoiceCell(
    icon: EntryIcon?,
    name: String,
    isSelected: Boolean,
    onSelect: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .choice(isSelected = isSelected)
            .clickable(onClick = onSelect)
            .padding(
                horizontal = 4.dp,
                vertical = 8.dp,
            ),
        verticalArrangement = Arrangement.spacedBy(4.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        IconTile(
            icon = icon,
            size = 40.dp,
        )

        Text(
            text = name,
            color = if (isSelected) Palette.accentStrong else Palette.text,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            style = textFont(
                size = FontSize.Caption,
                weight = FontWeight.Medium,
            ),
        )
    }
}

@Composable
private fun Modifier.choice(isSelected: Boolean): Modifier {
    val shape = RoundedCornerShape(LocalThemeStyle.current.corner.radius(16.dp))
    val fill = if (isSelected) Palette.accent.opacity(Emphasis.Subtle) else Color.Transparent
    val rim = if (isSelected) Palette.accent else Palette.accent.opacity(Emphasis.Soft)

    return clip(shape)
        .background(fill)
        .border(
            width = 1.dp,
            color = rim,
            shape = shape,
        )
}

@Composable
private fun DateCalendar(model: EntryModel) {
    var month by remember { mutableStateOf(model.date.yearMonth) }

    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            MonthButton(
                rotation = 180f,
                onSelect = { month = month.adding(months = -1) },
            )

            Text(
                text = "${month.year}年 ${month.month}月",
                modifier = Modifier.weight(1f),
                color = Palette.accentStrong,
                textAlign = TextAlign.Center,
                style = displayFont(size = FontSize.Body),
            )

            MonthButton(
                rotation = 0f,
                onSelect = { month = month.adding(months = 1) },
            )
        }

        Row(modifier = Modifier.fillMaxWidth()) {
            Weekday.week(startingOn = Weekday.sunday).forEach { weekday ->
                Text(
                    text = weekday.shortName,
                    modifier = Modifier.weight(1f),
                    color = Palette.subtext,
                    textAlign = TextAlign.Center,
                    style = textFont(size = FontSize.Caption),
                )
            }
        }

        month.weeks(startingOn = Weekday.sunday).forEach { week ->
            Row(modifier = Modifier.fillMaxWidth()) {
                week.forEach { day ->
                    Box(
                        modifier = Modifier.weight(1f),
                        contentAlignment = Alignment.Center,
                    ) {
                        if (day != null) {
                            DayCell(
                                day = day,
                                isSelected = day == model.date,
                                isToday = day == model.today,
                                onSelect = { model.select(day) },
                            )
                        } else {
                            Spacer(modifier = Modifier.height(dayCellSize))
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun MonthButton(
    rotation: Float,
    onSelect: () -> Unit,
) {
    Box(
        modifier = Modifier
            .size(36.dp)
            .clip(CircleShape)
            .clickable(onClick = onSelect),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            painter = painterResource(R.drawable.ic_chevron_right),
            contentDescription = null,
            modifier = Modifier
                .size(22.dp)
                .rotate(rotation),
            tint = Palette.accent,
        )
    }
}

@Composable
private fun DayCell(
    day: LocalDate,
    isSelected: Boolean,
    isToday: Boolean,
    onSelect: () -> Unit,
) {
    val fill = if (isSelected) Palette.accent else Color.Transparent
    val rim = if (isToday && !isSelected) Palette.accent else Color.Transparent

    Box(
        modifier = Modifier
            .size(dayCellSize)
            .clip(CircleShape)
            .background(fill)
            .border(
                width = 1.dp,
                color = rim,
                shape = CircleShape,
            ).clickable(onClick = onSelect),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = day.day.toString(),
            color = if (isSelected) Palette.backgroundTop else Palette.text,
            style = displayFont(size = FontSize.Body),
        )
    }
}

private const val KEY_ROWS = 5

private val minKeyHeight: Dp = 36.dp
private val maxKeyHeight: Dp = 72.dp
private val dayCellSize: Dp = 36.dp

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
import com.yossibank.kakeibot.features.screens.entry.model.categories
import com.yossibank.kakeibot.features.screens.entry.model.categoryText
import com.yossibank.kakeibot.features.screens.entry.model.dateText
import com.yossibank.kakeibot.features.screens.entry.model.expressionText
import com.yossibank.kakeibot.features.screens.entry.model.feeChoices
import com.yossibank.kakeibot.features.screens.entry.model.icon
import com.yossibank.kakeibot.features.screens.entry.model.newTemplateDraft
import com.yossibank.kakeibot.features.screens.entry.model.routeText
import com.yossibank.kakeibot.features.screens.entry.model.showsItems
import com.yossibank.kakeibot.features.screens.entry.model.walletTitle
import com.yossibank.kakeibot.features.screens.entry.model.wallets
import com.yossibank.kakeibot.features.shared.entrylist.EntryText
import com.yossibank.kakeibot.core.concepts.icon.Icon as EntryIcon

@Composable
internal fun CategoryGrid(
    model: EntryModel,
    modifier: Modifier = Modifier,
) {
    LazyVerticalGrid(
        columns = GridCells.Fixed(4),
        modifier = modifier.fillMaxSize(),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        items(
            items = model.output.categories,
            key = { it.id.toString() },
        ) { category ->
            ChoiceCell(
                icon = model.output.icon(of = category.iconId),
                name = category.name,
                isSelected = category.id == model.state.form.categoryId,
                onSelect = { model.state.select(category) },
            )
        }
    }
}

@Composable
internal fun WalletList(
    model: EntryModel,
    selection: Identifier<Wallet>?,
    onSelect: (Wallet) -> Unit,
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        items(
            items = model.output.wallets,
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
                    icon = model.output.icon(of = wallet.iconId),
                    size = 36.dp,
                )

                FittedText(
                    text = wallet.name,
                    modifier = Modifier.weight(1f),
                    color = Palette.text,
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
internal fun ChoiceCell(
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

        FittedText(
            text = name,
            color = if (isSelected) Palette.accentStrong else Palette.text,
            style = textFont(
                size = FontSize.Caption,
                weight = FontWeight.Medium,
            ),
        )
    }
}

@Composable
internal fun Modifier.choice(isSelected: Boolean): Modifier {
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

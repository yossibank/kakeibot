package com.yossibank.kakeibot.features.screens.entry.sheet

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.EntryItem
import com.yossibank.kakeibot.designsystem.components.date.shortName
import com.yossibank.kakeibot.designsystem.components.input.Keypad
import com.yossibank.kakeibot.designsystem.components.input.PlaceholderTextField
import com.yossibank.kakeibot.designsystem.components.input.SegmentSwitch
import com.yossibank.kakeibot.designsystem.components.surface.Hairline
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.components.text.FittedText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.LocalThemeStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.radius
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.features.screens.entry.model.EntryItemInput
import com.yossibank.kakeibot.features.screens.entry.model.EntryModel
import com.yossibank.kakeibot.features.screens.entry.model.RemovedItem
import com.yossibank.kakeibot.features.screens.entry.model.addItem
import com.yossibank.kakeibot.features.screens.entry.model.adjustToItems
import com.yossibank.kakeibot.features.screens.entry.model.canAdjustToItems
import com.yossibank.kakeibot.features.screens.entry.model.hasItemAdjustment
import com.yossibank.kakeibot.features.screens.entry.model.itemAdjustment
import com.yossibank.kakeibot.features.screens.entry.model.itemCount
import com.yossibank.kakeibot.features.screens.entry.model.itemNameSuggestions
import com.yossibank.kakeibot.features.screens.entry.model.itemTotals
import com.yossibank.kakeibot.features.screens.entry.model.quantityText
import com.yossibank.kakeibot.features.screens.entry.model.removeItem
import com.yossibank.kakeibot.features.screens.entry.model.restoreItem
import com.yossibank.kakeibot.features.screens.entry.model.setTaxIncluded
import com.yossibank.kakeibot.features.screens.entry.model.store
import com.yossibank.kakeibot.features.screens.entry.model.unitPrice
import com.yossibank.kakeibot.features.screens.entry.model.updateItem
import com.yossibank.kakeibot.features.shared.period.PeriodText
import kotlinx.coroutines.delay

@Composable
internal fun ItemRow(
    item: EntryItem.Draft,
    isEditing: Boolean,
    showsRate: Boolean,
    onSelect: () -> Unit,
    onRemove: () -> Unit,
) {
    val state = rememberSwipeToDismissBoxState()

    LaunchedEffect(state.currentValue) {
        if (state.currentValue == SwipeToDismissBoxValue.EndToStart) {
            onRemove()
        }
    }

    SwipeToDismissBox(
        state = state,
        enableDismissFromStartToEnd = false,
        backgroundContent = {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Palette.rose),
                contentAlignment = Alignment.CenterEnd,
            ) {
                Icon(
                    painter = painterResource(R.drawable.ic_trash),
                    contentDescription = null,
                    modifier = Modifier
                        .padding(end = 16.dp)
                        .size(20.dp),
                    tint = Palette.backgroundTop,
                )
            }
        },
    ) {
        ItemLine(
            item = item,
            isEditing = isEditing,
            showsRate = showsRate,
            onSelect = onSelect,
        )
    }
}

@Composable
private fun ItemLine(
    item: EntryItem.Draft,
    isEditing: Boolean,
    showsRate: Boolean,
    onSelect: () -> Unit,
) {
    val isNegative = item.amount < 0
    val fill = if (isEditing) Palette.accent.opacity(Emphasis.Subtle) else Color.Transparent

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(Palette.paper)
            .background(fill)
            .clickable(onClick = onSelect)
            .padding(
                horizontal = 4.dp,
                vertical = 8.dp,
            ),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(
            modifier = Modifier
                .weight(1f)
                .padding(start = if (isNegative) 12.dp else 0.dp),
            verticalArrangement = Arrangement.spacedBy(1.dp),
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(4.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                FittedText(
                    text = item.trimmedName,
                    color = if (isNegative) Palette.rose else Palette.text,
                    style = textFont(size = FontSize.Small),
                )

                val rate = item.taxRate

                if (showsRate && rate != null) {
                    Text(
                        text = "${rate.rawValue}%",
                        color = Palette.subtext,
                        style = textFont(size = FontSize.Micro),
                    )
                }
            }

            item.quantityText()?.let { text ->
                Text(
                    text = text,
                    color = Palette.subtext,
                    style = textFont(size = FontSize.Caption),
                )
            }
        }

        Text(
            text = AmountText.text(item.amount),
            color = if (isNegative) Palette.rose else Palette.text,
            style = textFont(size = FontSize.Small),
        )
    }
}

@Composable
internal fun SummaryLine(
    title: String,
    amount: Long?,
    detail: String? = null,
) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Text(
            text = title,
            modifier = Modifier.weight(1f),
            color = Palette.subtext,
            style = textFont(size = FontSize.Small),
        )

        Text(
            text = detail ?: AmountText.text(amount?.toInt() ?: 0),
            color = Palette.text,
            style = textFont(size = FontSize.Small),
        )
    }
}

@Composable
internal fun AdjustmentLine(model: EntryModel) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = "差額",
            color = Palette.amber,
            style = textFont(size = FontSize.Small),
        )

        if (model.canAdjustToItems) {
            Box(
                modifier = Modifier
                    .height(32.dp)
                    .clip(CircleShape)
                    .border(
                        width = 1.dp,
                        color = Palette.accent.opacity(Emphasis.Medium),
                        shape = CircleShape,
                    ).clickable(onClick = model::adjustToItems)
                    .padding(horizontal = 12.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = "調整",
                    color = Palette.accent,
                    style = textFont(
                        size = FontSize.Caption,
                        weight = FontWeight.SemiBold,
                    ),
                )
            }
        }

        Spacer(modifier = Modifier.weight(1f))

        Text(
            text = AmountText.text(model.itemAdjustment.toInt()),
            color = Palette.amber,
            style = textFont(size = FontSize.Small),
        )
    }
}

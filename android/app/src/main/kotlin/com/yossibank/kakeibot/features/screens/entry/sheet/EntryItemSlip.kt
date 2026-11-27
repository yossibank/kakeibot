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
import com.yossibank.kakeibot.designsystem.components.button.CircleIconButton
import com.yossibank.kakeibot.designsystem.components.input.Keypad
import com.yossibank.kakeibot.designsystem.components.input.PlaceholderTextField
import com.yossibank.kakeibot.designsystem.components.input.SegmentSwitch
import com.yossibank.kakeibot.designsystem.components.text.FittedText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.LocalThemeStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.radius
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.screens.entry.model.EntryModel
import com.yossibank.kakeibot.featuremodels.screens.entry.model.itemNameSuggestions
import com.yossibank.kakeibot.featuremodels.screens.entry.sheet.EntryItemModel
import com.yossibank.kakeibot.featuremodels.shared.amount.AmountText
import kotlinx.coroutines.delay

@Composable
fun EntryItemSlip(
    model: EntryModel,
    items: EntryItemModel,
) {
    val focus = LocalFocusManager.current

    val shape = RoundedCornerShape(
        topStart = 20.dp,
        topEnd = 20.dp,
    )

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(Palette.paper)
            .border(
                width = 1.dp,
                color = Palette.paperEdge,
                shape = shape,
            ).padding(
                horizontal = 16.dp,
                vertical = 12.dp,
            ),
        verticalArrangement = Arrangement.spacedBy(slipSpacing),
    ) {
        SlipHeader(items = items)

        NameField(items = items)

        Suggestions(
            model = model,
            items = items,
        )

        Equation(items = items)

        TaxRow(items = items)

        Keypad(
            calculator = items.state.fields.draft.activeCalculator,
            onKey = { key ->
                focus.clearFocus()
                items.state.press(key)
            },
            keyHeight = 44.dp,
        )

        SubmitButton(
            items = items,
            onSubmit = {
                focus.clearFocus()
                items.submit(model)
            },
        )
    }
}

@Composable
private fun SlipHeader(items: EntryItemModel) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Text(
            text = items.state.fields.draft.editing?.index?.let { "品目 ${it + 1} を変更" } ?: "品目を追加",
            modifier = Modifier.weight(1f),
            color = Palette.text,
            style = textFont(
                size = FontSize.Small,
                weight = FontWeight.SemiBold,
            ),
        )

        CircleIconButton(
            icon = R.drawable.ic_close,
            onClick = items.state::close,
            size = 36.dp,
            iconSize = 20.dp,
            fill = SolidColor(Color.Transparent),
            tint = Palette.subtext,
        )
    }
}

@Composable
private fun Suggestions(
    model: EntryModel,
    items: EntryItemModel,
) {
    val focus = LocalFocusManager.current
    val suggestions = model.output.itemNameSuggestions(items.state.fields.draft.name)

    if (suggestions.isNotEmpty()) {
        Row(
            modifier = Modifier.horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            suggestions.forEach { suggestion ->
                EntryItemChip(
                    title = suggestion,
                    isSelected = false,
                    onSelect = {
                        focus.clearFocus()
                        items.state.setName(suggestion)
                    },
                )
            }
        }
    }
}

@Composable
private fun TaxRow(items: EntryItemModel) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        listOf(
            null to "税込",
            AmountCalculator.TaxRate.reduced to "8%",
            AmountCalculator.TaxRate.standard to "10%",
        ).forEach { (rate, title) ->
            EntryItemChip(
                title = title,
                isSelected = items.state.fields.draft.taxRate == rate,
                onSelect = { items.state.select(taxRate = rate) },
            )
        }

        Spacer(modifier = Modifier.weight(1f))

        EntryItemChip(
            title = "値引",
            isSelected = items.state.fields.draft.isDiscount,
            onSelect = { items.state.toggleDiscount() },
        )

        EntryItemChip(
            title = "半額",
            isSelected = false,
            onSelect = items.state::halveUnit,
        )
    }
}

@Composable
private fun SubmitButton(
    items: EntryItemModel,
    onSubmit: () -> Unit,
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(48.dp)
            .clip(CircleShape)
            .background(
                if (items.state.fields.draft.canSubmit) {
                    Palette.accent
                } else {
                    Palette.accent.opacity(
                        Emphasis.Muted,
                    )
                },
            )
            .clickable(
                enabled = items.state.fields.draft.canSubmit,
                onClick = onSubmit,
            ),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = if (items.state.fields.draft.editing == null) "追加" else "変更",
            color = Palette.backgroundTop,
            style = textFont(
                size = FontSize.Body,
                weight = FontWeight.SemiBold,
            ),
        )
    }
}

@Composable
private fun NameField(items: EntryItemModel) {
    val focus = LocalFocusManager.current
    val shape = RoundedCornerShape(LocalThemeStyle.current.corner.radius(12.dp))

    PlaceholderTextField(
        value = items.state.fields.draft.name,
        onChange = { items.state.setName(it) },
        placeholder = "品名",
        style = textFont(size = FontSize.Body),
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(Palette.panel)
            .border(
                width = 1.dp,
                color = Palette.accent.opacity(Emphasis.Soft),
                shape = shape,
            ).padding(
                horizontal = 12.dp,
                vertical = namePadding,
            ),
        onDone = focus::clearFocus,
    )
}

@Composable
private fun Equation(items: EntryItemModel) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Token(
            label = "単価",
            value = AmountText.text(items.state.fields.draft.unit.amount),
            isSelected = items.state.fields.draft.target == EntryItemModel.Target.Unit,
            onSelect = { items.state.enter(EntryItemModel.Target.Unit) },
        )

        Operator(text = "×")

        Token(
            label = "数量",
            value = items.state.fields.draft.quantityValue.toString(),
            isSelected = items.state.fields.draft.target == EntryItemModel.Target.Quantity,
            onSelect = { items.state.enter(EntryItemModel.Target.Quantity) },
        )

        Spacer(modifier = Modifier.weight(1f))

        Operator(text = "=")

        FittedText(
            text = AmountText.text(items.state.fields.draft.lineAmount.toInt()),
            color = if (items.state.fields.draft.isDiscount) Palette.rose else Palette.accentStrong,
            style = displayFont(
                size = FontSize.Body,
                weight = FontWeight.Bold,
            ),
        )
    }
}

@Composable
private fun Token(
    label: String,
    value: String,
    isSelected: Boolean,
    onSelect: () -> Unit,
) {
    val shape = RoundedCornerShape(LocalThemeStyle.current.corner.radius(8.dp))
    val fill = if (isSelected) Palette.accent.opacity(Emphasis.Subtle) else Color.Transparent

    Row(
        modifier = Modifier
            .clip(shape)
            .background(fill)
            .clickable(onClick = onSelect)
            .padding(8.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = label,
            color = if (isSelected) Palette.accent else Palette.subtext,
            style = textFont(size = FontSize.Caption),
        )

        FittedText(
            text = value,
            color = if (isSelected) Palette.accentStrong else Palette.text,
            style = displayFont(
                size = FontSize.Body,
                weight = FontWeight.Bold,
            ),
        )
    }
}

@Composable
private fun Operator(text: String) {
    Text(
        text = text,
        color = Palette.subtext,
        style = textFont(size = FontSize.Body),
    )
}

@Composable
private fun EntryItemChip(
    title: String,
    isSelected: Boolean,
    onSelect: () -> Unit,
) {
    val fill = if (isSelected) Palette.accent.opacity(Emphasis.Soft) else Color.Transparent
    val rim = if (isSelected) Palette.accent else Palette.accent.opacity(Emphasis.Muted)

    Box(
        modifier = Modifier
            .height(30.dp)
            .clip(CircleShape)
            .background(fill)
            .border(
                width = 1.dp,
                color = rim,
                shape = CircleShape,
            ).clickable(onClick = onSelect)
            .padding(horizontal = 12.dp),
        contentAlignment = Alignment.Center,
    ) {
        FittedText(
            text = title,
            color = if (isSelected) Palette.accentStrong else Palette.text,
            style = textFont(
                size = FontSize.Caption,
                weight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
            ),
        )
    }
}

private val slipSpacing = 10.dp
private val namePadding = 10.dp

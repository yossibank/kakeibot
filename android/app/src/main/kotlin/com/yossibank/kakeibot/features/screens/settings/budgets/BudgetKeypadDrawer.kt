package com.yossibank.kakeibot.features.screens.settings.budgets

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.designsystem.components.button.PrimaryButton
import com.yossibank.kakeibot.designsystem.components.input.Keypad
import com.yossibank.kakeibot.designsystem.components.modal.BottomDrawer
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
import com.yossibank.kakeibot.featuremodels.screens.settings.budgets.suggestions
import com.yossibank.kakeibot.featuremodels.shared.model.perform
import com.yossibank.kakeibot.features.shared.model.EditSheet
import com.yossibank.kakeibot.features.shared.settingsparts.input.RoundIconButton

@Composable
fun BudgetKeypadDrawer(model: BudgetListModel) {
    if (model.state.editing != null) {
        EditSheet(
            flow = model.flow,
            onClose = model.state::cancelEditing,
        )
    }

    BottomDrawer(
        item = model.state.editing,
        title = { it.title },
        onClose = model.flow::close,
        padding = drawerPadding,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Drawer(model = model)
    }
}

@Composable
private fun ColumnScope.Drawer(model: BudgetListModel) {
    AmountText(
        amount = model.state.calculator.amount,
        style = displayFont(
            size = FontSize.LargeTitle,
            weight = FontWeight.Bold,
        ),
        color = Palette.accentStrong,
    )

    if (model.output.suggestions.isNotEmpty()) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            model.output.suggestions.forEach { suggestion ->
                SuggestionChip(
                    suggestion = suggestion,
                    isSelected = model.state.calculator.amount == suggestion.amount,
                    onSelect = { model.state.choose(suggestion) },
                    modifier = Modifier.weight(1f),
                )
            }
        }
    }

    Keypad(
        calculator = model.state.calculator,
        onKey = model.state::press,
        keyHeight = Metrics.keyHeight,
    )

    if (model.state.task.message.isNotEmpty()) {
        Text(
            text = model.state.task.message,
            modifier = Modifier.clickable(onClick = model.state.task::clear),
            color = Palette.rose,
            style = textFont(style = FontTextStyle.Caption),
        )
    }

    PrimaryButton(
        title = model.flow.output.saveTitle,
        onClick = { model.flow.perform { it.save() } },
        modifier = Modifier.fillMaxWidth(),
        isEnabled = model.flow.output.canSave,
    )

    if (model.output.editingAmount != null) {
        Text(
            text = "予算をなくす",
            modifier = Modifier
                .heightIn(min = 44.dp)
                .clip(CircleShape)
                .clickable { model.perform { it.clear() } }
                .padding(
                    horizontal = 16.dp,
                    vertical = 12.dp,
                ),
            color = Palette.rose,
            style = textFont(style = FontTextStyle.Footnote),
        )
    }
}

@Composable
private fun SuggestionChip(
    suggestion: BudgetListModel.Suggestion,
    isSelected: Boolean,
    onSelect: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val fill = if (isSelected) SolidColor(Palette.accent.opacity(Emphasis.Soft)) else Palette.card
    val rim = if (isSelected) Palette.accent else Palette.accent.opacity(Emphasis.Muted)

    Column(
        modifier = modifier
            .clip(CircleShape)
            .background(fill)
            .border(
                width = 1.dp,
                color = rim,
                shape = CircleShape,
            ).clickable(onClick = onSelect)
            .padding(vertical = 6.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        FittedText(
            text = suggestion.title,
            color = Palette.subtext,
            style = textFont(style = FontTextStyle.Caption2),
        )

        AmountText(
            amount = suggestion.amount,
            style = textFont(style = FontTextStyle.Caption),
        )
    }
}

private val drawerPadding = PaddingValues(
    start = 16.dp,
    top = 16.dp,
    end = 16.dp,
    bottom = 12.dp,
)

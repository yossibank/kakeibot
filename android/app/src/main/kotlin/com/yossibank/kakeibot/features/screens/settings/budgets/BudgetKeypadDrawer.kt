package com.yossibank.kakeibot.features.screens.settings.budgets

import androidx.activity.compose.BackHandler
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
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.designsystem.components.input.Keypad
import com.yossibank.kakeibot.designsystem.components.modal.DiscardDialog
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.features.shared.settingsparts.RoundIconButton
import kotlinx.coroutines.launch

@Composable
fun BudgetKeypadDrawer(
    model: BudgetListModel,
    onCleared: (BudgetListModel.Cleared) -> Unit,
) {
    var isConfirmingDiscard by remember { mutableStateOf(false) }

    fun close() {
        if (model.isChanged) {
            isConfirmingDiscard = true
        } else {
            model.cancelEditing()
        }
    }

    if (model.editing != null) {
        BackHandler(onBack = ::close)
    }

    AnimatedVisibility(
        visible = model.editing != null,
        enter = fadeIn(),
        exit = fadeOut(),
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Palette.scrim.opacity(Emphasis.Muted))
                .clickable(
                    interactionSource = remember { MutableInteractionSource() },
                    indication = null,
                    onClick = ::close,
                ),
        )
    }

    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.BottomCenter,
    ) {
        AnimatedVisibility(
            visible = model.editing != null,
            enter = slideInVertically { it },
            exit = slideOutVertically { it },
        ) {
            Drawer(
                model = model,
                onClose = ::close,
                onCleared = onCleared,
            )
        }
    }

    if (isConfirmingDiscard) {
        DiscardDialog(
            onDiscard = {
                isConfirmingDiscard = false
                model.cancelEditing()
            },
            onKeep = { isConfirmingDiscard = false },
        )
    }
}

@Composable
private fun Drawer(
    model: BudgetListModel,
    onClose: () -> Unit,
    onCleared: (BudgetListModel.Cleared) -> Unit,
) {
    val scope = rememberCoroutineScope()
    val shape = RoundedCornerShape(
        topStart = 28.dp,
        topEnd = 28.dp,
    )

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(Palette.backgroundTop)
            .border(
                width = 1.dp,
                color = Palette.accent.opacity(Emphasis.Soft),
                shape = shape,
            ).pointerInput(Unit) {}
            .navigationBarsPadding()
            .padding(
                start = 16.dp,
                top = 16.dp,
                end = 16.dp,
                bottom = 12.dp,
            ),
        verticalArrangement = Arrangement.spacedBy(12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(modifier = Modifier.fillMaxWidth()) {
            Text(
                text = (model.editing ?: BudgetListModel.Target.Total).title,
                modifier = Modifier.align(Alignment.Center),
                color = Palette.accentStrong,
                maxLines = 1,
                style = displayFont(size = FontSize.Body),
            )

            RoundIconButton(
                icon = R.drawable.ic_close,
                onSelect = onClose,
                modifier = Modifier.align(Alignment.CenterEnd),
            )
        }

        AmountText(
            amount = model.calculator.amount,
            style = displayFont(
                size = FontSize.LargeTitle,
                weight = FontWeight.Bold,
            ),
            color = Palette.accentStrong,
        )

        if (model.suggestions.isNotEmpty()) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                model.suggestions.forEach { suggestion ->
                    SuggestionChip(
                        suggestion = suggestion,
                        isSelected = model.calculator.amount == suggestion.amount,
                        onSelect = { model.choose(suggestion) },
                        modifier = Modifier.weight(1f),
                    )
                }
            }
        }

        Keypad(
            calculator = model.calculator,
            onKey = model::press,
            keyHeight = 52.dp,
        )

        if (model.message.isNotEmpty()) {
            Text(
                text = model.message,
                color = Palette.rose,
                style = textFont(style = FontTextStyle.Caption),
            )
        }

        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp)
                .clip(CircleShape)
                .background(
                    if (model.canSave) {
                        Brush.verticalGradient(listOf(Palette.accentDeep, Palette.accent))
                    } else {
                        Brush.verticalGradient(listOf(Palette.hint, Palette.hint))
                    },
                ).clickable(enabled = model.canSave) {
                    scope.launch { model.save() }
                },
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = model.saveTitle,
                color = Palette.backgroundTop,
                style = textFont(
                    size = FontSize.Body,
                    weight = FontWeight.SemiBold,
                ),
            )
        }

        if (model.editingAmount != null) {
            Text(
                text = "予算をなくす",
                modifier = Modifier
                    .heightIn(min = 44.dp)
                    .clip(CircleShape)
                    .clickable {
                        scope.launch { model.clear()?.let(onCleared) }
                    }.padding(
                        horizontal = 16.dp,
                        vertical = 12.dp,
                    ),
                color = Palette.rose,
                style = textFont(style = FontTextStyle.Footnote),
            )
        }
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
        Text(
            text = suggestion.title,
            color = Palette.subtext,
            maxLines = 1,
            style = textFont(style = FontTextStyle.Caption2),
        )

        AmountText(
            amount = suggestion.amount,
            style = textFont(style = FontTextStyle.Caption),
        )
    }
}

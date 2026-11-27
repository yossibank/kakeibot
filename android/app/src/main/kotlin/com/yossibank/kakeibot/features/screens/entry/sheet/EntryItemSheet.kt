package com.yossibank.kakeibot.features.screens.entry.sheet

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
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
import com.yossibank.kakeibot.designsystem.components.input.SegmentSwitch
import com.yossibank.kakeibot.designsystem.components.modal.UndoNotice
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.LocalThemeStyle
import com.yossibank.kakeibot.designsystem.theme.Metrics
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.radius
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.screens.entry.model.EntryItemEditor
import com.yossibank.kakeibot.featuremodels.screens.entry.model.EntryModel
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenParts
import kotlinx.coroutines.delay

@Composable
fun EntryItemSheet(
    parts: ScreenParts,
    model: EntryModel,
    onClose: () -> Unit,
) {
    val editor = remember(model) { EntryItemEditor(wait = parts.wait) }

    BackHandler {
        if (editor.isOpen) {
            editor.close()
        } else {
            onClose()
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(Palette.background)
                .pointerInput(Unit) {}
                .statusBarsPadding()
                .navigationBarsPadding()
                .imePadding(),
        ) {
            SheetHeader(onClose = onClose)

            Column(
                modifier = Modifier
                    .weight(1f)
                    .verticalScroll(rememberScrollState())
                    .padding(
                        horizontal = 20.dp,
                        vertical = 8.dp,
                    ),
            ) {
                EntryItemReceipt(
                    model = model,
                    editor = editor,
                )
            }

            if (editor.isOpen) {
                EntryItemSlip(
                    model = model,
                    editor = editor,
                )
            } else {
                AddBar(onAdd = { editor.open(model) })
            }
        }

        ItemUndoNotice(
            model = model,
            editor = editor,
        )
    }
}

@Composable
private fun SheetHeader(onClose: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(
                horizontal = 20.dp,
                vertical = 12.dp,
            ),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = "品目",
            color = Palette.text,
            style = textFont(
                size = FontSize.Body,
                weight = FontWeight.SemiBold,
            ),
        )

        CircleIconButton(
            icon = R.drawable.ic_check,
            onClick = onClose,
            modifier = Modifier.align(Alignment.CenterEnd),
            size = 36.dp,
            iconSize = 20.dp,
            fill = SolidColor(Palette.accent),
            tint = Palette.backgroundTop,
        )
    }
}

@Composable
private fun BoxScope.ItemUndoNotice(
    model: EntryModel,
    editor: EntryItemEditor,
) {
    if (editor.removed.current != null) {
        UndoNotice(
            title = "品目を消しました",
            icon = R.drawable.ic_trash,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .navigationBarsPadding()
                .padding(
                    start = 20.dp,
                    end = 20.dp,
                    bottom = 76.dp,
                ),
            onUndo = { editor.restore(model) },
        )
    }
}

@Composable
private fun AddBar(onAdd: () -> Unit) {
    Box(
        modifier = Modifier
            .padding(
                horizontal = 20.dp,
                vertical = 8.dp,
            ).fillMaxWidth()
            .height(Metrics.buttonHeight)
            .clip(CircleShape)
            .background(Palette.accent)
            .clickable(onClick = onAdd),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = "＋ 品目を追加",
            color = Palette.backgroundTop,
            style = textFont(
                size = FontSize.Body,
                weight = FontWeight.SemiBold,
            ),
        )
    }
}

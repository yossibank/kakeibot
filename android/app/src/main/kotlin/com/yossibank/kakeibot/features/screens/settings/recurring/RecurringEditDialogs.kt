package com.yossibank.kakeibot.features.screens.settings.recurring

import androidx.compose.foundation.layout.Column
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.text.font.FontWeight
import com.yossibank.kakeibot.designsystem.components.modal.DeleteDialog
import com.yossibank.kakeibot.designsystem.components.modal.DiscardDialog
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.RecurringEditPrompt

@Composable
fun RecurringEditDialogs(
    prompt: RecurringEditPrompt?,
    isHidden: Boolean,
    canSave: Boolean,
    onDismiss: (RecurringEditPrompt) -> Unit,
    onDiscard: () -> Unit,
    onDelete: () -> Unit,
    onSaveHiding: () -> Unit,
    onDiscardHiding: () -> Unit,
) {
    val current = prompt ?: return
    val dismiss = { onDismiss(current) }

    when (current) {
        RecurringEditPrompt.Discard -> {
            DiscardDialog(
                onDiscard = {
                    dismiss()
                    onDiscard()
                },
                onKeep = dismiss,
            )
        }

        RecurringEditPrompt.Delete -> {
            DeleteDialog(
                title = "この固定費を削除しますか",
                message = "これまでに作った記録は残ります",
                onConfirm = {
                    dismiss()
                    onDelete()
                },
                onDismiss = dismiss,
            )
        }

        RecurringEditPrompt.Hide -> {
            UnsavedHideDialog(
                isHidden = isHidden,
                canSave = canSave,
                onSave = {
                    dismiss()
                    onSaveHiding()
                },
                onDiscard = {
                    dismiss()
                    onDiscardHiding()
                },
                onKeep = dismiss,
            )
        }
    }
}

@Composable
private fun UnsavedHideDialog(
    isHidden: Boolean,
    canSave: Boolean,
    onSave: () -> Unit,
    onDiscard: () -> Unit,
    onKeep: () -> Unit,
) {
    val verb = if (isHidden) "表示" else "非表示"

    AlertDialog(
        onDismissRequest = onKeep,
        confirmButton = {
            Column(horizontalAlignment = Alignment.End) {
                if (canSave) {
                    TextButton(onClick = onSave) {
                        Text(
                            text = "保存して$verb",
                            color = Palette.accent,
                        )
                    }
                }

                TextButton(onClick = onDiscard) {
                    Text(
                        text = "捨てて$verb",
                        color = Palette.rose,
                    )
                }

                TextButton(onClick = onKeep) {
                    Text(
                        text = "入力に戻る",
                        color = Palette.subtext,
                    )
                }
            }
        },
        title = {
            Text(
                text = "保存していない変更があります",
                color = Palette.text,
                style = textFont(
                    size = FontSize.Body,
                    weight = FontWeight.SemiBold,
                ),
            )
        },
        text = {
            Text(
                text = "入力した内容は、保存しないと残りません",
                color = Palette.subtext,
            )
        },
        containerColor = Palette.backgroundTop,
    )
}

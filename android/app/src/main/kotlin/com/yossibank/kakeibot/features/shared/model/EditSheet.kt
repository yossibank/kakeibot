package com.yossibank.kakeibot.features.shared.model

import androidx.activity.compose.BackHandler
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
import com.yossibank.kakeibot.featuremodels.shared.model.EditFlow
import com.yossibank.kakeibot.featuremodels.shared.model.perform
import com.yossibank.kakeibot.featuremodels.shared.notice.Deletion

@Composable
fun <Saved : Any> EditSheet(
    flow: EditFlow<Saved>,
    deleting: String = "",
    note: String? = null,
    onHide: () -> Unit = {},
    onDelete: (Deletion) -> Unit = {},
    onSaved: (Saved) -> Unit = {},
    onClose: () -> Unit,
) {
    OnOutcome(flow.state.outcome) { outcome ->
        outcome.saved?.let(onSaved)

        if (outcome.isHidden == true) {
            onHide()
        }

        outcome.deletion?.let(onDelete)

        if (outcome.closes) {
            onClose()
        }
    }

    BackHandler(onBack = flow::back)

    PromptDialogs(
        flow = flow,
        deleting = deleting,
        note = note,
    )
}

@Composable
private fun PromptDialogs(
    flow: EditFlow<*>,
    deleting: String,
    note: String?,
) {
    when (val prompt = flow.state.prompt.current) {
        EditFlow.Prompt.discard -> {
            DiscardDialog(
                onDiscard = flow::discard,
                onKeep = { flow.state.prompt.close(prompt) },
            )
        }

        EditFlow.Prompt.delete -> {
            DeleteDialog(
                title = deleting,
                message = note,
                onConfirm = {
                    flow.state.prompt.close(prompt)
                    flow.perform { it.delete() }
                },
                onDismiss = { flow.state.prompt.close(prompt) },
            )
        }

        EditFlow.Prompt.hideChanges -> {
            UnsavedHideDialog(
                isHidden = flow.output.isHidden,
                canSave = flow.output.canSave,
                onSave = {
                    flow.state.prompt.close(prompt)
                    flow.perform { it.saveTogglingHidden() }
                },
                onDiscard = {
                    flow.state.prompt.close(prompt)
                    flow.perform { it.setHidden(!it.output.isHidden) }
                },
                onKeep = { flow.state.prompt.close(prompt) },
            )
        }

        EditFlow.Prompt.menu, EditFlow.Prompt.hide, null -> {}
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

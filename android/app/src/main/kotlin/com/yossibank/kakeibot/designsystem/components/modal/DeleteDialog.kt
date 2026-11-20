package com.yossibank.kakeibot.designsystem.components.modal

import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.text.font.FontWeight
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.textFont

@Composable
fun DeleteDialog(
    title: String,
    message: String? = null,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit,
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = {
            TextButton(onClick = onConfirm) {
                Text(
                    text = "削除する",
                    color = Palette.rose,
                )
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(
                    text = "やめる",
                    color = Palette.subtext,
                )
            }
        },
        title = {
            Text(
                text = title,
                color = Palette.text,
                style = textFont(
                    size = FontSize.Body,
                    weight = FontWeight.SemiBold,
                ),
            )
        },
        text = message?.let {
            {
                Text(
                    text = it,
                    color = Palette.subtext,
                )
            }
        },
        containerColor = Palette.backgroundTop,
    )
}

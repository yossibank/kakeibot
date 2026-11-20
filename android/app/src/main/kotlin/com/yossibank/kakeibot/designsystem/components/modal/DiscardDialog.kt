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
fun DiscardDialog(
    onDiscard: () -> Unit,
    onKeep: () -> Unit,
) {
    AlertDialog(
        onDismissRequest = onKeep,
        confirmButton = {
            TextButton(onClick = onDiscard) {
                Text(
                    text = "保存せずに閉じる",
                    color = Palette.rose,
                )
            }
        },
        dismissButton = {
            TextButton(onClick = onKeep) {
                Text(
                    text = "入力に戻る",
                    color = Palette.subtext,
                )
            }
        },
        title = {
            Text(
                text = "保存せずに閉じますか",
                color = Palette.text,
                style = textFont(
                    size = FontSize.Body,
                    weight = FontWeight.SemiBold,
                ),
            )
        },
        text = {
            Text(
                text = "入力した内容は残りません",
                color = Palette.subtext,
            )
        },
        containerColor = Palette.backgroundTop,
    )
}

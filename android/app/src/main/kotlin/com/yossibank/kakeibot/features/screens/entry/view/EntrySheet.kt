package com.yossibank.kakeibot.features.screens.entry.view

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.LocalThemeStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.radius
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.features.screens.entry.model.EntryModel
import com.yossibank.kakeibot.features.screens.entry.parts.EntryDeck
import com.yossibank.kakeibot.features.screens.entry.parts.EntrySlip
import com.yossibank.kakeibot.features.screens.entry.parts.EntryTypeSwitch
import com.yossibank.kakeibot.store.database.AppDatabase
import kotlinx.coroutines.launch

@Composable
fun EntrySheet(
    database: AppDatabase,
    today: LocalDate,
    editing: Identifier<Entry>?,
    onClose: () -> Unit,
) {
    val model = remember(database, editing) {
        EntryModel(
            database = database,
            today = today,
            editing = editing,
        )
    }

    var isConfirmingDelete by remember { mutableStateOf(false) }

    val scope = rememberCoroutineScope()

    LaunchedEffect(model) {
        model.load()
    }

    BackHandler(onBack = onClose)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Palette.background)
            .pointerInput(Unit) {}
            .statusBarsPadding()
            .navigationBarsPadding()
            .imePadding()
            .padding(
                horizontal = 16.dp,
                vertical = 12.dp,
            ),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            EntryTypeSwitch(
                selection = model.type,
                onSelect = model::select,
            )

            Spacer(modifier = Modifier.weight(1f))

            CloseButton(onClose = onClose)
        }

        EntrySlip(model = model)

        DeckPanel(modifier = Modifier.weight(1f)) {
            EntryDeck(
                model = model,
                modifier = Modifier.weight(1f),
            )

            Text(
                text = model.message ?: "",
                color = Palette.rose,
                maxLines = 1,
                style = textFont(size = FontSize.Caption),
            )

            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                SaveButton(
                    title = if (model.isEditing) "保存する" else "記録する",
                    modifier = Modifier.weight(1f),
                    onSave = {
                        scope.launch {
                            if (model.save()) {
                                onClose()
                            }
                        }
                    },
                )

                if (model.isEditing) {
                    RoundButton(onSelect = { isConfirmingDelete = true }) {
                        Icon(
                            painter = painterResource(R.drawable.ic_trash),
                            contentDescription = null,
                            modifier = Modifier.size(22.dp),
                            tint = Palette.rose,
                        )
                    }
                } else {
                    RoundButton(
                        onSelect = {
                            scope.launch {
                                if (model.save()) {
                                    model.startNext()
                                }
                            }
                        },
                    ) {
                        Text(
                            text = "続けて",
                            color = Palette.accent,
                            style = textFont(
                                size = FontSize.Caption,
                                weight = FontWeight.SemiBold,
                            ),
                        )
                    }
                }
            }
        }
    }

    if (isConfirmingDelete) {
        DeleteDialog(
            onConfirm = {
                isConfirmingDelete = false

                scope.launch {
                    if (model.delete()) {
                        onClose()
                    }
                }
            },
            onDismiss = { isConfirmingDelete = false },
        )
    }
}

@Composable
private fun DeckPanel(
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.() -> Unit,
) {
    val shape = RoundedCornerShape(LocalThemeStyle.current.corner.radius(24.dp))

    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(shape)
            .background(Palette.panel)
            .border(
                width = 1.dp,
                color = Palette.accent.opacity(Emphasis.Soft),
                shape = shape,
            ).padding(12.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
        content = content,
    )
}

@Composable
private fun CloseButton(onClose: () -> Unit) {
    Box(
        modifier = Modifier
            .size(36.dp)
            .clip(CircleShape)
            .background(Palette.card)
            .border(
                width = 1.dp,
                color = Palette.accent.opacity(Emphasis.Muted),
                shape = CircleShape,
            ).clickable(onClick = onClose),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            painter = painterResource(R.drawable.ic_close),
            contentDescription = null,
            modifier = Modifier.size(20.dp),
            tint = Palette.subtext,
        )
    }
}

@Composable
private fun SaveButton(
    title: String,
    onSave: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Box(
        modifier = modifier
            .height(52.dp)
            .clip(CircleShape)
            .background(Brush.verticalGradient(listOf(Palette.accentDeep, Palette.accent)))
            .clickable(onClick = onSave),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = title,
            color = Palette.backgroundTop,
            style = textFont(
                size = FontSize.Body,
                weight = FontWeight.SemiBold,
            ),
        )
    }
}

@Composable
private fun RoundButton(
    onSelect: () -> Unit,
    content: @Composable () -> Unit,
) {
    Box(
        modifier = Modifier
            .size(52.dp)
            .clip(CircleShape)
            .border(
                width = 1.dp,
                color = Palette.accent.opacity(Emphasis.Medium),
                shape = CircleShape,
            ).clickable(onClick = onSelect),
        contentAlignment = Alignment.Center,
    ) {
        content()
    }
}

@Composable
private fun DeleteDialog(
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
                text = "この記録を削除しますか",
                color = Palette.text,
                style = textFont(
                    size = FontSize.Body,
                    weight = FontWeight.SemiBold,
                ),
            )
        },
        containerColor = Palette.backgroundTop,
    )
}

package com.yossibank.kakeibot.features.screens.entry.view

import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.designsystem.components.button.PrimaryButton
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.Metrics
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.screens.entry.model.EntryModel
import com.yossibank.kakeibot.featuremodels.screens.entry.model.canSave
import com.yossibank.kakeibot.featuremodels.screens.entry.model.opensKeypadOnSave
import com.yossibank.kakeibot.featuremodels.screens.entry.model.saveTitle
import kotlinx.coroutines.launch

@Composable
internal fun ActionBar(
    model: EntryModel,
    onSaved: () -> Unit,
    onDelete: () -> Unit,
) {
    val scope = rememberCoroutineScope()

    Row(
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        PrimaryButton(
            title = model.output.saveTitle,
            onClick = {
                if (model.output.opensKeypadOnSave) {
                    model.state.focus(EntryModel.Field.Amount)
                } else {
                    scope.launch {
                        if (model.save()) {
                            onSaved()
                        }
                    }
                }
            },
            modifier = Modifier.weight(1f),
            isEnabled = model.output.canSave || model.output.opensKeypadOnSave,
        )

        if (model.output.isEditing) {
            RoundButton(onSelect = onDelete) {
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

@Composable
private fun RoundButton(
    onSelect: () -> Unit,
    content: @Composable () -> Unit,
) {
    Box(
        modifier = Modifier
            .size(Metrics.buttonHeight)
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

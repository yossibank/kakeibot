package com.yossibank.kakeibot.features.screens.entry.view

import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.designsystem.components.button.PrimaryButton
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.Metrics
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.screens.entry.model.EntryModel
import com.yossibank.kakeibot.featuremodels.screens.entry.model.canSave
import com.yossibank.kakeibot.featuremodels.screens.entry.model.isEditing
import com.yossibank.kakeibot.featuremodels.screens.entry.model.opensKeypadOnSave
import com.yossibank.kakeibot.featuremodels.screens.entry.model.saveTitle
import com.yossibank.kakeibot.featuremodels.shared.model.perform

@Composable
internal fun ActionBar(model: EntryModel) {
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
                    model.perform { it.save() }
                }
            },
            modifier = Modifier.weight(1f),
            isEnabled = model.output.canSave || model.output.opensKeypadOnSave,
        )

        if (!model.output.isEditing) {
            ContinueButton(
                isEnabled = model.output.canSave,
                onSelect = { model.perform { it.saveAndContinue() } },
            )
        }
    }
}

@Composable
private fun ContinueButton(
    isEnabled: Boolean,
    onSelect: () -> Unit,
) {
    Box(
        modifier = Modifier
            .size(Metrics.buttonHeight)
            .alpha(if (isEnabled) 1f else DISABLED_ALPHA)
            .clip(CircleShape)
            .border(
                width = 1.dp,
                color = Palette.accent.opacity(Emphasis.Medium),
                shape = CircleShape,
            ).clickable(
                enabled = isEnabled,
                onClick = onSelect,
            ),
        contentAlignment = Alignment.Center,
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

private const val DISABLED_ALPHA = 0.4f

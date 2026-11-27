package com.yossibank.kakeibot.features.screens.entry.view

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.designsystem.components.button.CircleIconButton
import com.yossibank.kakeibot.designsystem.components.text.FittedText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.LocalThemeStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.radius
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.screens.entry.model.EntryModel
import com.yossibank.kakeibot.featuremodels.screens.entry.model.hasRecent
import com.yossibank.kakeibot.featuremodels.screens.entry.model.isEditing
import com.yossibank.kakeibot.featuremodels.screens.entry.model.newTemplateDraft
import com.yossibank.kakeibot.featuremodels.screens.entry.model.select
import com.yossibank.kakeibot.featuremodels.screens.entry.model.showsRecent
import com.yossibank.kakeibot.featuremodels.screens.entry.model.showsVoice
import com.yossibank.kakeibot.featuremodels.screens.entry.voice.EntryVoiceFlow
import com.yossibank.kakeibot.featuremodels.shared.model.ErrorNotice
import com.yossibank.kakeibot.featuremodels.shared.model.perform
import com.yossibank.kakeibot.features.screens.entry.parts.EntryDeck
import com.yossibank.kakeibot.features.screens.entry.parts.EntryRecentRow
import com.yossibank.kakeibot.features.screens.entry.parts.EntrySlip
import com.yossibank.kakeibot.features.screens.entry.parts.EntryTypeSwitch
import com.yossibank.kakeibot.features.screens.entry.voice.EntryVoiceCard
import com.yossibank.kakeibot.features.screens.entry.voice.rememberVoiceStarter

@Composable
internal fun EntryBody(
    model: EntryModel,
    voice: EntryVoiceFlow,
    today: LocalDate,
    onClose: () -> Unit,
) {
    val startVoice = rememberVoiceStarter(
        voice = voice,
        model = model,
        today = today,
    )

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
        EntryHeader(
            model = model,
            onClose = onClose,
        )

        EntrySlip(
            model = model,
            onOpenItems = { model.state.openItems() },
            onVoice = startVoice.takeIf {
                voice.input.isAvailable && model.output.showsVoice && !voice.output.isActive
            },
            listening = voice.output.listening,
        )

        DeckPanel(modifier = Modifier.weight(1f)) {
            EntryDeckContent(
                model = model,
                voice = voice,
                today = today,
            )
        }
    }
}

@Composable
private fun EntryHeader(
    model: EntryModel,
    onClose: () -> Unit,
) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        EntryTypeSwitch(
            selection = model.state.fields.form.type,
            onSelect = { model.select(type = it) },
        )

        Spacer(modifier = Modifier.weight(1f))

        if (model.output.isEditing) {
            CircleIconButton(
                icon = R.drawable.ic_trash,
                onClick = { model.perform { it.delete() } },
                size = 36.dp,
                iconSize = 20.dp,
                tint = Palette.rose,
            )

            Spacer(modifier = Modifier.width(8.dp))
        }

        CircleIconButton(
            icon = R.drawable.ic_close,
            onClick = onClose,
            size = 36.dp,
            iconSize = 20.dp,
            tint = Palette.subtext,
        )
    }
}

@Composable
private fun ColumnScope.EntryDeckContent(
    model: EntryModel,
    voice: EntryVoiceFlow,
    today: LocalDate,
) {
    val context = LocalContext.current
    val isInfo = model.state.notices.error.tone == ErrorNotice.Tone.info

    if (voice.output.isActive) {
        EntryVoiceCard(
            flow = voice,
            model = model,
            today = today,
            onOpenSettings = {
                voice.cancel()

                context.startActivity(
                    Intent(
                        Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.fromParts("package", context.packageName, null),
                    ),
                )
            },
            modifier = Modifier.weight(1f),
        )
    } else {
        EntryDeck(
            model = model,
            onOpenItems = { model.state.openItems() },
            onSaveTemplate = {
                model.state.presented.overlay.show(
                    EntryModel.Overlay.Template(model.output.newTemplateDraft()),
                )
            },
            modifier = Modifier.weight(1f),
        )
    }

    FittedText(
        text = model.state.notices.error.message,
        modifier = Modifier.clickable(onClick = model.state.notices.error::clear),
        color = if (isInfo) Palette.accent else Palette.rose,
        style = textFont(size = FontSize.Caption),
    )

    if (!voice.output.isActive && model.output.showsRecent && model.output.hasRecent) {
        EntryRecentRow(model = model)
    } else {
        ActionBar(model = model)
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

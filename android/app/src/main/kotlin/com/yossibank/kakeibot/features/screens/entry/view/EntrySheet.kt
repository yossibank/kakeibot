package com.yossibank.kakeibot.features.screens.entry.view

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.designsystem.components.modal.DiscardDialog
import com.yossibank.kakeibot.designsystem.theme.Haptic
import com.yossibank.kakeibot.designsystem.theme.HapticEffect
import com.yossibank.kakeibot.featuremodels.screens.entry.model.EntryModel
import com.yossibank.kakeibot.featuremodels.screens.entry.model.close
import com.yossibank.kakeibot.featuremodels.screens.entry.voice.EntryVoiceFlow
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenParts
import com.yossibank.kakeibot.featuremodels.shared.model.perform
import com.yossibank.kakeibot.featuremodels.shared.notice.EntryChange
import com.yossibank.kakeibot.featuremodels.shared.notice.EntryNoticeModel
import com.yossibank.kakeibot.features.screens.entry.sheet.EntryItemSheet
import com.yossibank.kakeibot.features.screens.entry.voice.EntryVoiceNotice
import com.yossibank.kakeibot.features.screens.settings.templates.TemplateEditSheet
import com.yossibank.kakeibot.features.shared.model.OnOutcome
import com.yossibank.kakeibot.features.shared.notice.EntryNoticeBanner

@Composable
fun EntrySheet(
    parts: ScreenParts,
    today: LocalDate,
    editing: Identifier<Entry>?,
    date: LocalDate?,
    onChange: (EntryChange) -> Unit,
    onClose: () -> Unit,
) {
    val model = remember(parts, editing, date) {
        EntryModel(
            parts = parts,
            today = today,
            editing = editing,
            date = date ?: today,
        )
    }

    val notice = remember(parts) { EntryNoticeModel(parts) }
    val voice = rememberEntryVoice(model = model, parts = parts)

    fun close() {
        if (model.close()) {
            onClose()
        }
    }

    EntrySheetEffects(
        model = model,
        voice = voice,
        notice = notice,
        today = today,
        onChange = onChange,
        onClose = onClose,
        onBack = ::close,
    )

    Box(modifier = Modifier.fillMaxSize()) {
        EntryBody(
            model = model,
            voice = voice,
            today = today,
            onClose = ::close,
        )

        EntryOverlay(
            model = model,
            notice = notice,
            voice = voice,
            parts = parts,
            onClose = onClose,
        )
    }
}

@Composable
private fun rememberEntryVoice(
    model: EntryModel,
    parts: ScreenParts,
): EntryVoiceFlow {
    val context = LocalContext.current

    return remember(model) {
        EntryVoiceFlow(
            context = context,
            clock = parts.clock,
        )
    }
}

@Composable
private fun EntrySheetEffects(
    model: EntryModel,
    voice: EntryVoiceFlow,
    notice: EntryNoticeModel,
    today: LocalDate,
    onChange: (EntryChange) -> Unit,
    onClose: () -> Unit,
    onBack: () -> Unit,
) {
    SideEffect {
        model.setToday(today)
    }

    LaunchedEffect(model) {
        model.load()
    }

    DisposableEffect(voice) {
        onDispose(voice::close)
    }

    HapticEffect(
        haptic = Haptic.LightImpact,
        trigger = voice.state.startCount,
    )

    HapticEffect(
        haptic = Haptic.LightImpact,
        trigger = voice.state.endCount,
    )

    BackHandler(onBack = onBack)
    BackHandler(enabled = voice.output.isActive, onBack = voice::cancel)

    OnOutcome(model.state.outcome) { outcome ->
        when (outcome) {
            is EntryModel.Outcome.Closed -> {
                onChange(outcome.change)
                onClose()
            }

            is EntryModel.Outcome.Continued -> {
                notice.show(outcome.change)
            }
        }
    }

    model.state.task.Timer()
}

@Composable
private fun BoxScope.EntryOverlay(
    model: EntryModel,
    notice: EntryNoticeModel,
    voice: EntryVoiceFlow,
    parts: ScreenParts,
    onClose: () -> Unit,
) {
    EntryNoticeLayer(
        notice = notice,
        voice = voice,
        model = model,
    )

    EntryPresentedLayer(
        model = model,
        parts = parts,
        onClose = onClose,
    )
}

@Composable
private fun BoxScope.EntryNoticeLayer(
    notice: EntryNoticeModel,
    voice: EntryVoiceFlow,
    model: EntryModel,
) {
    val voiceNotice = voice.state.notice

    val modifier = Modifier
        .align(Alignment.BottomCenter)
        .navigationBarsPadding()
        .padding(
            start = 20.dp,
            end = 20.dp,
            bottom = 96.dp,
        )

    if (voiceNotice == null) {
        EntryNoticeBanner(
            model = notice,
            modifier = modifier,
        )
    } else {
        EntryVoiceNotice(
            notice = voiceNotice,
            onUndo = { voice.undoLast(model) },
            onClose = voice::clearNotice,
            modifier = modifier,
        )
    }
}

@Composable
private fun EntryPresentedLayer(
    model: EntryModel,
    parts: ScreenParts,
    onClose: () -> Unit,
) {
    (model.state.presented.current as? EntryModel.Presented.Template)?.let { template ->
        TemplateEditSheet(
            parts = parts,
            draft = template.draft,
            onSave = { model.perform { it.receiveTemplate() } },
            onClose = model.state.presented::closeAll,
        )
    }

    AnimatedVisibility(
        visible = model.state.presented.current == EntryModel.Presented.Items,
        enter = slideInVertically { it },
        exit = slideOutVertically { it },
    ) {
        EntryItemSheet(
            model = model,
            onClose = model.state.presented::closeAll,
        )
    }

    if (model.state.presented.current == EntryModel.Presented.Discard) {
        DiscardDialog(
            onDiscard = {
                model.state.presented.closeAll()
                onClose()
            },
            onKeep = model.state.presented::closeAll,
        )
    }
}

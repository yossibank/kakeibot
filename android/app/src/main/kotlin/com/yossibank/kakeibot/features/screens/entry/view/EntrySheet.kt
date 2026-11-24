package com.yossibank.kakeibot.features.screens.entry.view

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplateDraft
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.designsystem.components.button.CircleIconButton
import com.yossibank.kakeibot.designsystem.components.modal.DeleteDialog
import com.yossibank.kakeibot.designsystem.components.text.FittedText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.Haptic
import com.yossibank.kakeibot.designsystem.theme.HapticEffect
import com.yossibank.kakeibot.designsystem.theme.LocalThemeStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.radius
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.features.screens.entry.model.EntryModel
import com.yossibank.kakeibot.features.screens.entry.model.apply
import com.yossibank.kakeibot.features.screens.entry.model.applyRecent
import com.yossibank.kakeibot.features.screens.entry.model.applyTransfer
import com.yossibank.kakeibot.features.screens.entry.model.categoryText
import com.yossibank.kakeibot.features.screens.entry.model.dateText
import com.yossibank.kakeibot.features.screens.entry.model.expressionText
import com.yossibank.kakeibot.features.screens.entry.model.hasRecent
import com.yossibank.kakeibot.features.screens.entry.model.newTemplateDraft
import com.yossibank.kakeibot.features.screens.entry.model.routeText
import com.yossibank.kakeibot.features.screens.entry.model.showsVoice
import com.yossibank.kakeibot.features.screens.entry.model.walletTitle
import com.yossibank.kakeibot.features.screens.entry.parts.EntryDeck
import com.yossibank.kakeibot.features.screens.entry.parts.EntryRecentRow
import com.yossibank.kakeibot.features.screens.entry.parts.EntrySlip
import com.yossibank.kakeibot.features.screens.entry.parts.EntryTypeSwitch
import com.yossibank.kakeibot.features.screens.entry.sheet.EntryItemSheet
import com.yossibank.kakeibot.features.screens.entry.voice.EntryVoiceCard
import com.yossibank.kakeibot.features.screens.entry.voice.EntryVoiceFlow
import com.yossibank.kakeibot.features.screens.entry.voice.EntryVoiceNotice
import com.yossibank.kakeibot.features.screens.entry.voice.rememberVoiceStarter
import com.yossibank.kakeibot.features.screens.settings.templates.TemplateEditSheet
import com.yossibank.kakeibot.features.shared.model.ScreenClock
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
            clock = ScreenClock.system,
            today = today,
            editing = editing,
        )
    }

    var isConfirmingDelete by remember { mutableStateOf(false) }
    var isShowingItems by remember { mutableStateOf(false) }
    var templateDraft: EntryTemplateDraft? by remember { mutableStateOf(null) }

    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    val voice = remember(model) {
        EntryVoiceFlow(
            context = context,
            scope = scope,
            clock = ScreenClock.system,
        )
    }

    val startVoice = rememberVoiceStarter(
        voice = voice,
        model = model,
        today = today,
    )

    SideEffect {
        model.state.today = today
    }

    LaunchedEffect(model) {
        model.load()
    }

    DisposableEffect(voice) {
        onDispose(voice::close)
    }

    BackHandler(onBack = onClose)

    BackHandler(enabled = voice.output.isActive, onBack = voice::cancel)

    HapticEffect(
        haptic = Haptic.LightImpact,
        trigger = voice.state.startCount,
    )

    HapticEffect(
        haptic = Haptic.LightImpact,
        trigger = voice.state.endCount,
    )

    Box(modifier = Modifier.fillMaxSize()) {
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
                    selection = model.state.form.type,
                    onSelect = model::select,
                )

                Spacer(modifier = Modifier.weight(1f))

                CircleIconButton(
                    icon = R.drawable.ic_close,
                    onClick = onClose,
                    size = 36.dp,
                    iconSize = 20.dp,
                    tint = Palette.subtext,
                )
            }

            EntrySlip(
                model = model,
                onOpenItems = { isShowingItems = true },
                onVoice = startVoice.takeIf {
                    voice.input.isAvailable && model.output.showsVoice && !voice.output.isActive
                },
                listening = voice.output.listening,
            )

            DeckPanel(modifier = Modifier.weight(1f)) {
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
                        onOpenItems = { isShowingItems = true },
                        onSaveTemplate = { templateDraft = model.output.newTemplateDraft() },
                        modifier = Modifier.weight(1f),
                    )
                }

                FittedText(
                    text = model.state.task.message,
                    color = Palette.rose,
                    style = textFont(size = FontSize.Caption),
                )

                if (!voice.output.isActive && model.output.showsRecent && model.output.hasRecent) {
                    EntryRecentRow(model = model)
                } else {
                    ActionBar(
                        model = model,
                        onSaved = onClose,
                        onDelete = { isConfirmingDelete = true },
                    )
                }
            }
        }

        voice.state.notice?.let { notice ->
            EntryVoiceNotice(
                notice = notice,
                onUndo = { voice.undoLast(model) },
                onClose = voice::clearNotice,
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .navigationBarsPadding()
                    .padding(
                        start = 20.dp,
                        end = 20.dp,
                        bottom = 96.dp,
                    ),
            )
        }

        templateDraft?.let { draft ->
            TemplateEditSheet(
                database = database,
                draft = draft,
                onSave = {
                    templateDraft = null

                    scope.launch {
                        model.reloadTemplates()
                    }
                },
                onClose = { templateDraft = null },
            )
        }

        AnimatedVisibility(
            visible = isShowingItems,
            enter = slideInVertically { it },
            exit = slideOutVertically { it },
        ) {
            EntryItemSheet(
                model = model,
                onClose = { isShowingItems = false },
            )
        }
    }

    if (isConfirmingDelete) {
        DeleteDialog(
            title = "この記録を削除しますか",
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

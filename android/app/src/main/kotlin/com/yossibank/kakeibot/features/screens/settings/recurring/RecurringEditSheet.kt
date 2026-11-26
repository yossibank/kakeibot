package com.yossibank.kakeibot.features.screens.settings.recurring

import android.Manifest
import android.content.Intent
import android.os.Build
import android.provider.Settings
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.core.app.NotificationManagerCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LifecycleEventEffect
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.date.HolidayShift
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.title
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.designsystem.components.button.PrimaryButton
import com.yossibank.kakeibot.designsystem.components.input.PlaceholderTextField
import com.yossibank.kakeibot.designsystem.components.input.SegmentSwitch
import com.yossibank.kakeibot.designsystem.components.modal.BottomDrawer
import com.yossibank.kakeibot.designsystem.components.modal.DeleteDialog
import com.yossibank.kakeibot.designsystem.components.modal.DiscardDialog
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.RecurringEditModel
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.RecurringEditPrompt
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.RecurringPanel
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.RecurringText
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.autoPlan
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.canSave
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.isChanged
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.isLoanRepayment
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.isNotificationDenied
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.open
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.plannedTotal
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.previewRow
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.saveTitle
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.select
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenParts
import com.yossibank.kakeibot.featuremodels.shared.model.perform
import com.yossibank.kakeibot.featuremodels.shared.notice.Deletion
import com.yossibank.kakeibot.features.shared.model.OnOutcome
import com.yossibank.kakeibot.features.shared.notification.rememberNotificationPermission
import com.yossibank.kakeibot.features.shared.settingsparts.input.RoundIconButton
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsCaption
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsDivider
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsFrame
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsHeader

@Composable
fun RecurringEditSheet(
    parts: ScreenParts,
    today: LocalDate,
    type: Entry.Kind,
    editingId: Identifier<Recurring>?,
    onClose: () -> Unit,
    onDelete: (Deletion) -> Unit,
    onHide: () -> Unit,
) {
    val model = remember(parts, editingId) {
        RecurringEditModel(
            parts = parts,
            today = today,
            type = type,
            editingId = editingId,
        )
    }

    SideEffect {
        model.state.today = today
    }

    val focus = LocalFocusManager.current
    val notification = rememberNotificationPermission()

    LaunchedEffect(model) {
        model.load()
        model.refreshAuthorization(notification.permission)
    }

    LifecycleEventEffect(Lifecycle.Event.ON_RESUME) {
        model.refreshAuthorization(notification.permission)
    }

    model.state.task.Timer()

    fun open(next: RecurringPanel) {
        focus.clearFocus()
        model.open(next)
    }

    fun close() {
        model.state.panel = null

        if (model.output.isChanged) {
            model.state.ask(RecurringEditPrompt.Discard)
        } else {
            onClose()
        }
    }

    fun setHidden(isHidden: Boolean) {
        model.perform { it.setHidden(isHidden) }
    }

    fun save(hiding: Boolean = false) {
        model.state.panel = null

        model.perform {
            if (hiding) {
                it.saveTogglingHidden(notification.permission)
            } else {
                it.save(notification.permission)
            }
        }
    }

    OnOutcome(model.state.outcome) { outcome ->
        if (outcome.isHidden == true) {
            onHide()
        }

        outcome.deletion?.let(onDelete)

        if (outcome.closes) {
            onClose()
        }
    }

    BackHandler {
        if (model.state.panel != null) {
            model.state.panel = null
        } else {
            close()
        }
    }

    SettingsFrame(
        title = if (model.output.isEditing) "固定費を編集" else "固定費を追加",
        isRoot = false,
        onBack = ::close,
        followsKeyboard = true,
        trailing = {
            if (model.output.isEditing) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    HideButton(
                        isHidden = model.input.isHidden,
                        onSelect = {
                            if (model.output.isChanged) {
                                model.state.ask(RecurringEditPrompt.Hide)
                            } else {
                                setHidden(!model.input.isHidden)
                            }
                        },
                    )

                    RoundIconButton(
                        icon = R.drawable.ic_trash,
                        onSelect = { model.state.ask(RecurringEditPrompt.Delete) },
                    )
                }
            }
        },
        overlay = {
            BottomDrawer(
                item = model.state.panel,
                title = { it.title },
                onClose = { model.state.panel = null },
            ) { current ->
                RecurringPanelBody(
                    panel = current,
                    model = model,
                    onClose = { model.state.panel = null },
                )
            }
        },
    ) {
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            if (!model.output.isEditing) {
                SegmentSwitch(
                    selection = model.state.form.type,
                    options = typeOptions,
                    onSelect = model::select,
                    modifier = Modifier.fillMaxWidth(),
                )
            }

            Column(verticalArrangement = Arrangement.spacedBy(previewSpacing)) {
                RecurringRowCard(row = model.output.previewRow)

                SettingsCaption(text = "一覧では、このカードで並びます")
            }

            PlaceholderTextField(
                value = model.state.form.memo,
                onChange = { memo -> model.state.update { copy(memo = memo) } },
                placeholder = RecurringText.namePrompt(model.state.form.type),
                style = textFont(style = FontTextStyle.Body),
                modifier = Modifier
                    .fillMaxWidth()
                    .card()
                    .padding(16.dp),
            )

            RecurringQuickCard(
                model = model,
                onOpen = ::open,
            )

            RecurringDetailRows(
                rows = model.detailRows,
                onOpen = ::open,
            )

            if (model.output.isLoanRepayment &&
                (model.output.plannedTotal != null || model.output.autoPlan != null)
            ) {
                RecurringLoanPlan(
                    model = model,
                    onMatch = model.state::useAutoCount,
                )
            }

            if (model.output.isNotificationDenied) {
                DeniedBanner(onOpen = notification::openSettings)
            }
        }

        if (model.state.task.message.isNotEmpty()) {
            Text(
                text = model.state.task.message,
                modifier = Modifier.clickable(onClick = model.state.task::clear),
                color = Palette.rose,
                style = textFont(style = FontTextStyle.Caption),
            )
        }

        PrimaryButton(
            title = model.output.saveTitle,
            onClick = { save() },
            modifier = Modifier.fillMaxWidth(),
            isEnabled = model.output.canSave,
        )
    }

    RecurringEditDialogs(
        prompt = model.state.prompt,
        isHidden = model.input.isHidden,
        canSave = model.output.canSave,
        onDismiss = model.state::closePrompt,
        onDiscard = onClose,
        onDelete = { model.perform { it.delete() } },
        onSaveHiding = { save(hiding = true) },
        onDiscardHiding = { setHidden(!model.input.isHidden) },
    )
}

private val previewSpacing = 6.dp
private val typeOptions = Entry.Kind.entries.map { it to it.title }

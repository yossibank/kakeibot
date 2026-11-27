package com.yossibank.kakeibot.features.screens.settings.recurring

import android.Manifest
import android.content.Intent
import android.os.Build
import android.provider.Settings
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
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.RecurringPanel
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.RecurringText
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.autoPlan
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.isLoanRepayment
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.isNotificationDenied
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.open
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.plannedTotal
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.previewRow
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.select
import com.yossibank.kakeibot.featuremodels.shared.model.EditFlow
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenParts
import com.yossibank.kakeibot.featuremodels.shared.model.perform
import com.yossibank.kakeibot.featuremodels.shared.notice.Deletion
import com.yossibank.kakeibot.features.shared.model.EditSheet
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
    val notification = rememberNotificationPermission()
    val focus = LocalFocusManager.current

    val model = remember(parts, editingId) {
        RecurringEditModel(
            parts = parts,
            today = today,
            type = type,
            editingId = editingId,
            permission = notification.permission,
        )
    }

    SideEffect {
        model.setToday(today)
    }

    LaunchedEffect(model) {
        model.load()
        model.refreshAuthorization()
    }

    LifecycleEventEffect(Lifecycle.Event.ON_RESUME) {
        model.refreshAuthorization()
    }

    fun open(next: RecurringPanel) {
        focus.clearFocus()
        model.open(next)
    }

    EditSheet(
        flow = model.flow,
        deleting = "この固定費を削除しますか",
        note = "これまでに作った記録は残ります",
        onHide = onHide,
        onDelete = onDelete,
        onClose = onClose,
    )

    RecurringEditFrame(
        model = model,
        onOpen = ::open,
        onOpenSettings = notification::openSettings,
    )
}

@Composable
private fun RecurringEditFrame(
    model: RecurringEditModel,
    onOpen: (RecurringPanel) -> Unit,
    onOpenSettings: () -> Unit,
) {
    SettingsFrame(
        title = if (model.flow.output.isEditing) "固定費を編集" else "固定費を追加",
        isRoot = false,
        onBack = model.flow::close,
        followsKeyboard = true,
        trailing = { EditActions(model = model) },
        overlay = { RecurringDrawer(model = model) },
    ) {
        RecurringEditContent(
            model = model,
            onOpen = onOpen,
            onOpenSettings = onOpenSettings,
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState()),
        )

        SaveButton(model = model)
    }
}

@Composable
private fun EditActions(model: RecurringEditModel) {
    if (model.flow.output.isEditing) {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            HideButton(
                isHidden = model.flow.output.isHidden,
                onSelect = { model.flow.perform { it.toggleHidden() } },
            )

            RoundIconButton(
                icon = R.drawable.ic_trash,
                onSelect = { model.flow.state.prompt.show(EditFlow.Prompt.delete) },
            )
        }
    }
}

@Composable
private fun RecurringDrawer(model: RecurringEditModel) {
    BottomDrawer(
        item = model.state.panel.current,
        title = { it.title },
        onClose = model.state.panel::closeAll,
    ) { current ->
        RecurringPanelBody(
            panel = current,
            model = model,
            onClose = model.state.panel::closeAll,
        )
    }
}

@Composable
private fun RecurringEditContent(
    model: RecurringEditModel,
    onOpen: (RecurringPanel) -> Unit,
    onOpenSettings: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        if (!model.flow.output.isEditing) {
            SegmentSwitch(
                selection = model.state.form.type,
                options = typeOptions,
                onSelect = model::select,
                modifier = Modifier.fillMaxWidth(),
            )
        }

        PreviewCard(model = model)

        NameField(model = model)

        RecurringQuickCard(
            model = model,
            onOpen = onOpen,
        )

        RecurringDetailRows(
            rows = model.detailRows,
            onOpen = onOpen,
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
            DeniedBanner(onOpen = onOpenSettings)
        }
    }
}

@Composable
private fun PreviewCard(model: RecurringEditModel) {
    Column(verticalArrangement = Arrangement.spacedBy(previewSpacing)) {
        RecurringRowCard(row = model.output.previewRow)

        SettingsCaption(text = "一覧では、このカードで並びます")
    }
}

@Composable
private fun NameField(model: RecurringEditModel) {
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
}

@Composable
private fun SaveButton(model: RecurringEditModel) {
    if (model.state.errorNotice.message.isNotEmpty()) {
        Text(
            text = model.state.errorNotice.message,
            modifier = Modifier.clickable(onClick = model.state.errorNotice::clear),
            color = Palette.rose,
            style = textFont(style = FontTextStyle.Caption),
        )
    }

    PrimaryButton(
        title = model.flow.output.saveTitle,
        onClick = { model.flow.perform { it.save() } },
        modifier = Modifier.fillMaxWidth(),
        isEnabled = model.flow.output.canSave,
    )
}

private val previewSpacing = 6.dp
private val typeOptions = Entry.Kind.entries.map { it to it.title }

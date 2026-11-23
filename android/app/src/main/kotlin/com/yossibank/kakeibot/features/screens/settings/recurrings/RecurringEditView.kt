package com.yossibank.kakeibot.features.screens.settings.recurrings

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
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
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
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.features.shared.notification.rememberNotificationPermission
import com.yossibank.kakeibot.features.shared.period.title
import com.yossibank.kakeibot.features.shared.settingsparts.RoundIconButton
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsCaption
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsDivider
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsFrame
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsHeader
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.writes.types.Deletion
import kotlinx.coroutines.launch

enum class RecurringPanel(
    val title: String,
) {
    Amount("金額"),
    Start("始まり"),
    End("終わり"),
    Holiday("休日なら"),
    Closing("金額の決め方"),
    Fee("手数料"),
    Count("回数"),
    Remind("前に知らせる"),
}

@Composable
fun RecurringEditView(
    database: AppDatabase,
    today: LocalDate,
    type: Entry.Kind,
    editingId: Identifier<Recurring>?,
    onClose: () -> Unit,
    onDelete: (Deletion) -> Unit,
    onHide: () -> Unit,
) {
    val model = remember(database, editingId) {
        RecurringEditModel(
            database = database,
            today = today,
            type = type,
            editingId = editingId,
        )
    }

    SideEffect {
        model.today = today
    }

    val focus = LocalFocusManager.current
    val scope = rememberCoroutineScope()
    val permission = rememberNotificationPermission()

    var panel by remember { mutableStateOf<RecurringPanel?>(null) }
    var prompt by remember { mutableStateOf<RecurringEditPrompt?>(null) }

    LaunchedEffect(model) {
        model.load()
    }

    fun open(next: RecurringPanel) {
        focus.clearFocus()

        if (next == RecurringPanel.Count) {
            model.prepareCount()
        }

        panel = next
    }

    fun close() {
        panel = null

        if (model.isChanged) {
            prompt = RecurringEditPrompt.Discard
        } else {
            onClose()
        }
    }

    fun setHidden(isHidden: Boolean) {
        scope.launch {
            if (model.setHidden(isHidden)) {
                if (isHidden) {
                    onHide()
                }

                onClose()
            }
        }
    }

    fun save(hiding: Boolean = false) {
        panel = null

        scope.launch {
            if (!model.save()) {
                return@launch
            }

            if (model.form.remindDaysBefore != null) {
                permission.requestIfNeeded()
            }

            if (hiding) {
                setHidden(!model.isHidden)
            } else {
                onClose()
            }
        }
    }

    BackHandler {
        if (panel != null) {
            panel = null
        } else {
            close()
        }
    }

    SettingsFrame(
        title = if (model.isEditing) "固定費を編集" else "固定費を追加",
        isRoot = false,
        onBack = ::close,
        followsKeyboard = true,
        trailing = {
            if (model.isEditing) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    HideButton(
                        isHidden = model.isHidden,
                        onSelect = {
                            if (model.isChanged) {
                                prompt = RecurringEditPrompt.Hide
                            } else {
                                setHidden(!model.isHidden)
                            }
                        },
                    )

                    RoundIconButton(
                        icon = R.drawable.ic_trash,
                        onSelect = { prompt = RecurringEditPrompt.Delete },
                    )
                }
            }
        },
        overlay = {
            BottomDrawer(
                item = panel,
                title = { it.title },
                onClose = { panel = null },
            ) { current ->
                RecurringPanelBody(
                    panel = current,
                    model = model,
                    onClose = { panel = null },
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
            if (!model.isEditing) {
                SegmentSwitch(
                    selection = model.form.type,
                    options = typeOptions,
                    onSelect = model::select,
                    modifier = Modifier.fillMaxWidth(),
                )
            }

            Column(verticalArrangement = Arrangement.spacedBy(previewSpacing)) {
                RecurringRowCard(row = model.previewRow)

                SettingsCaption(text = "一覧では、このカードで並びます")
            }

            PlaceholderTextField(
                value = model.form.memo,
                onChange = { memo -> model.update { copy(memo = memo) } },
                placeholder = RecurringText.namePrompt(model.form.type),
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

            if (model.isLoanRepayment &&
                (model.plannedTotal != null || model.autoPlan != null)
            ) {
                RecurringLoanPlan(
                    model = model,
                    onMatch = model::useAutoCount,
                )
            }

            if (model.form.remindDaysBefore != null && !permission.isAllowed) {
                DeniedBanner(onOpen = permission::openSettings)
            }
        }

        if (model.message.isNotEmpty()) {
            Text(
                text = model.message,
                modifier = Modifier.clickable(onClick = model::clearMessage),
                color = Palette.rose,
                style = textFont(style = FontTextStyle.Caption),
            )
        }

        PrimaryButton(
            title = model.saveTitle,
            onClick = { save() },
            modifier = Modifier.fillMaxWidth(),
            isEnabled = model.canSave,
        )
    }

    RecurringEditDialogs(
        prompt = prompt,
        isHidden = model.isHidden,
        canSave = model.canSave,
        onDismiss = { prompt = null },
        onDiscard = onClose,
        onDelete = {
            scope.launch {
                model.delete()?.let {
                    onDelete(it)
                    onClose()
                }
            }
        },
        onSaveHiding = { save(hiding = true) },
        onDiscardHiding = { setHidden(!model.isHidden) },
    )
}

@Composable
private fun HideButton(
    isHidden: Boolean,
    onSelect: () -> Unit,
) {
    Text(
        text = if (isHidden) "表示する" else "非表示",
        modifier = Modifier
            .height(40.dp)
            .clip(CircleShape)
            .background(Palette.card)
            .border(
                width = 1.dp,
                color = Palette.accent.opacity(Emphasis.Muted),
                shape = CircleShape,
            ).clickable(onClick = onSelect)
            .padding(
                horizontal = 14.dp,
                vertical = 10.dp,
            ),
        color = Palette.accent,
        style = textFont(
            size = FontSize.Small,
            weight = FontWeight.SemiBold,
        ),
    )
}

@Composable
private fun DeniedBanner(onOpen: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .card()
            .clickable(onClick = onOpen)
            .padding(16.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            painter = painterResource(R.drawable.ic_bell),
            contentDescription = null,
            modifier = Modifier.size(20.dp),
            tint = Palette.amber,
        )

        Text(
            text = "通知が届かない状態です",
            modifier = Modifier.weight(1f),
            color = Palette.text,
            style = textFont(style = FontTextStyle.Subheadline),
        )

        Text(
            text = "許可する",
            color = Palette.accent,
            style = textFont(
                style = FontTextStyle.Subheadline,
                weight = FontWeight.SemiBold,
            ),
        )

        Icon(
            painter = painterResource(R.drawable.ic_chevron_right),
            contentDescription = null,
            modifier = Modifier.size(16.dp),
            tint = Palette.accent,
        )
    }
}

private val previewSpacing = 6.dp

private val typeOptions = Entry.Kind.entries.map { it to it.title }

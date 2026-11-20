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
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.designsystem.components.input.SegmentSwitch
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
import com.yossibank.kakeibot.features.shared.period.title
import com.yossibank.kakeibot.features.shared.settingsparts.RoundIconButton
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsCaption
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsDivider
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

    val context = LocalContext.current
    val focus = LocalFocusManager.current
    val scope = rememberCoroutineScope()

    var panel by remember { mutableStateOf<RecurringPanel?>(null) }
    var isConfirmingDiscard by remember { mutableStateOf(false) }
    var isConfirmingHide by remember { mutableStateOf(false) }
    var isConfirmingDelete by remember { mutableStateOf(false) }

    val permission = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission(),
    ) { isGranted ->
        model.isNotificationAllowed = isGranted
    }

    fun refreshAuthorization() {
        model.isNotificationAllowed =
            NotificationManagerCompat.from(context).areNotificationsEnabled()
    }

    LaunchedEffect(model) {
        model.load()
        refreshAuthorization()
    }

    LifecycleEventEffect(Lifecycle.Event.ON_RESUME) {
        refreshAuthorization()
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
            isConfirmingDiscard = true
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

            val needsPermission = model.remindDaysBefore != null &&
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                !NotificationManagerCompat.from(context).areNotificationsEnabled()

            if (needsPermission) {
                permission.launch(Manifest.permission.POST_NOTIFICATIONS)
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

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Palette.background)
            .pointerInput(Unit) {},
    ) {
        Column(
            modifier = Modifier
                .statusBarsPadding()
                .navigationBarsPadding()
                .imePadding()
                .padding(
                    horizontal = 16.dp,
                    vertical = 12.dp,
                ),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            SettingsHeader(
                title = if (model.isEditing) "固定費を編集" else "固定費を追加",
                isRoot = false,
                onBack = ::close,
            ) {
                if (model.isEditing) {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        HideButton(
                            isHidden = model.isHidden,
                            onSelect = {
                                if (model.isChanged) {
                                    isConfirmingHide = true
                                } else {
                                    setHidden(!model.isHidden)
                                }
                            },
                        )

                        RoundIconButton(
                            icon = R.drawable.ic_trash,
                            onSelect = { isConfirmingDelete = true },
                        )
                    }
                }
            }

            Column(
                modifier = Modifier
                    .weight(1f)
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                if (!model.isEditing) {
                    SegmentSwitch(
                        selection = model.type,
                        options = typeOptions,
                        onSelect = model::select,
                        modifier = Modifier.fillMaxWidth(),
                    )
                }

                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    RecurringRowCard(row = model.previewRow)

                    SettingsCaption(text = "一覧では、このカードで並びます")
                }

                NameField(model = model)

                RecurringQuickCard(
                    model = model,
                    onOpen = ::open,
                )

                DetailRows(
                    model = model,
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

                if (model.isNotificationDenied) {
                    DeniedBanner(
                        onOpen = {
                            val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)

                            context.startActivity(intent)
                        },
                    )
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

            SaveButton(
                title = model.saveTitle,
                isEnabled = model.canSave,
                onSave = { save() },
            )
        }

        PanelDrawer(
            panel = panel,
            model = model,
            onClose = { panel = null },
        )
    }

    if (isConfirmingDiscard) {
        DiscardDialog(
            onDiscard = {
                isConfirmingDiscard = false
                onClose()
            },
            onKeep = { isConfirmingDiscard = false },
        )
    }

    if (isConfirmingDelete) {
        DeleteDialog(
            title = "この固定費を削除しますか",
            message = "これまでに作った記録は残ります",
            onConfirm = {
                isConfirmingDelete = false

                scope.launch {
                    model.delete()?.let {
                        onDelete(it)
                        onClose()
                    }
                }
            },
            onDismiss = { isConfirmingDelete = false },
        )
    }

    if (isConfirmingHide) {
        UnsavedHideDialog(
            isHidden = model.isHidden,
            canSave = model.canSave,
            onSave = {
                isConfirmingHide = false
                save(hiding = true)
            },
            onDiscard = {
                isConfirmingHide = false
                setHidden(!model.isHidden)
            },
            onKeep = { isConfirmingHide = false },
        )
    }
}

@Composable
private fun PanelDrawer(
    panel: RecurringPanel?,
    model: RecurringEditModel,
    onClose: () -> Unit,
) {
    AnimatedVisibility(
        visible = panel != null,
        enter = fadeIn(),
        exit = fadeOut(),
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Palette.scrim.opacity(Emphasis.Muted))
                .clickable(
                    interactionSource = remember { MutableInteractionSource() },
                    indication = null,
                    onClick = onClose,
                ),
        )
    }

    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.BottomCenter,
    ) {
        AnimatedVisibility(
            visible = panel != null,
            enter = slideInVertically { it },
            exit = slideOutVertically { it },
        ) {
            val current = remember(panel) { panel } ?: return@AnimatedVisibility
            val shape = RoundedCornerShape(
                topStart = 28.dp,
                topEnd = 28.dp,
            )

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(shape)
                    .background(Palette.backgroundTop)
                    .border(
                        width = 1.dp,
                        color = Palette.accent.opacity(Emphasis.Soft),
                        shape = shape,
                    ).pointerInput(Unit) {}
                    .navigationBarsPadding()
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Box(modifier = Modifier.fillMaxWidth()) {
                    Text(
                        text = current.title,
                        modifier = Modifier.align(Alignment.Center),
                        color = Palette.accentStrong,
                        style = displayFont(size = FontSize.Body),
                    )

                    RoundIconButton(
                        icon = R.drawable.ic_close,
                        onSelect = onClose,
                        modifier = Modifier.align(Alignment.CenterEnd),
                    )
                }

                RecurringPanelBody(
                    panel = current,
                    model = model,
                    onClose = onClose,
                )
            }
        }
    }
}

@Composable
private fun NameField(model: RecurringEditModel) {
    val style = textFont(style = FontTextStyle.Body)

    val prompt = when (model.type) {
        Entry.Kind.expense -> "家賃・サブスクなど"
        Entry.Kind.income -> "給料・年金など"
        Entry.Kind.transfer -> "カードの引き落とし・積立など"
    }

    BasicTextField(
        value = model.memo,
        onValueChange = { model.memo = it },
        modifier = Modifier
            .fillMaxWidth()
            .card()
            .padding(16.dp),
        textStyle = style.copy(color = Palette.text),
        singleLine = true,
        cursorBrush = SolidColor(Palette.accent),
        decorationBox = { field ->
            if (model.memo.isEmpty()) {
                Text(
                    text = prompt,
                    color = Palette.hint,
                    style = style,
                )
            }

            field()
        },
    )
}

@Composable
private fun DetailRows(
    model: RecurringEditModel,
    onOpen: (RecurringPanel) -> Unit,
) {
    val rows = buildList {
        if (model.type == Entry.Kind.transfer) {
            if (model.isLoanRepayment) {
                val count = model.repaymentCount

                add(
                    DetailRow(
                        panel = RecurringPanel.Count,
                        icon = R.drawable.ic_repeat,
                        value = when {
                            count == null -> "決めない"
                            model.usesAutoCount -> "自動 · $count 回"
                            else -> "$count 回"
                        },
                        isEmpty = count == null,
                    ),
                )
            } else if (model.canUseClosingDay) {
                add(
                    DetailRow(
                        panel = RecurringPanel.Closing,
                        icon = R.drawable.ic_card,
                        value = RecurringText.closingDay(model.closingDay),
                        isEmpty = model.closingDay == null,
                    ),
                )
            }

            add(
                DetailRow(
                    panel = RecurringPanel.Fee,
                    icon = R.drawable.ic_bank,
                    value = if (model.fee > 0) AmountText.text(amount = model.fee) else "なし",
                    isEmpty = model.fee == 0,
                ),
            )
        }

        add(
            DetailRow(
                panel = RecurringPanel.Start,
                icon = R.drawable.ic_calendar,
                value = RecurringText.date(model.startDate),
                isEmpty = false,
            ),
        )

        add(
            DetailRow(
                panel = RecurringPanel.End,
                icon = R.drawable.ic_calendar,
                value = model.scheduledEndDate?.let(RecurringText::date) ?: "なし",
                isEmpty = model.scheduledEndDate == null,
            ),
        )

        add(
            DetailRow(
                panel = RecurringPanel.Holiday,
                icon = R.drawable.ic_calendar,
                value = model.holidayShift.title,
                isEmpty = model.holidayShift == HolidayShift.none,
            ),
        )

        add(
            DetailRow(
                panel = RecurringPanel.Remind,
                icon = R.drawable.ic_bell,
                value = RecurringText.remind(model.remindDaysBefore),
                isEmpty = model.remindDaysBefore == null,
            ),
        )
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .card(),
    ) {
        rows.forEachIndexed { index, row ->
            if (index > 0) {
                SettingsDivider()
            }

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(min = 52.dp)
                    .clickable { onOpen(row.panel) }
                    .padding(horizontal = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(
                    painter = painterResource(row.icon),
                    contentDescription = null,
                    modifier = Modifier.size(20.dp),
                    tint = Palette.accent,
                )

                Text(
                    text = row.panel.title,
                    modifier = Modifier.weight(1f),
                    color = Palette.text,
                    style = textFont(style = FontTextStyle.Subheadline),
                )

                Text(
                    text = row.value,
                    color = if (row.isEmpty) Palette.hint else Palette.accentStrong,
                    maxLines = 1,
                    style = textFont(style = FontTextStyle.Subheadline),
                )

                Icon(
                    painter = painterResource(R.drawable.ic_chevron_right),
                    contentDescription = null,
                    modifier = Modifier.size(16.dp),
                    tint = Palette.subtext,
                )
            }
        }
    }
}

private data class DetailRow(
    val panel: RecurringPanel,
    val icon: Int,
    val value: String,
    val isEmpty: Boolean,
)

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

@Composable
private fun SaveButton(
    title: String,
    isEnabled: Boolean,
    onSave: () -> Unit,
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(52.dp)
            .clip(CircleShape)
            .background(
                if (isEnabled) {
                    Brush.verticalGradient(listOf(Palette.accentDeep, Palette.accent))
                } else {
                    SolidColor(Palette.hint)
                },
            ).clickable(
                enabled = isEnabled,
                onClick = onSave,
            ),
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
private fun UnsavedHideDialog(
    isHidden: Boolean,
    canSave: Boolean,
    onSave: () -> Unit,
    onDiscard: () -> Unit,
    onKeep: () -> Unit,
) {
    val verb = if (isHidden) "表示" else "非表示"

    AlertDialog(
        onDismissRequest = onKeep,
        confirmButton = {
            Column(horizontalAlignment = Alignment.End) {
                if (canSave) {
                    TextButton(onClick = onSave) {
                        Text(
                            text = "保存して$verb",
                            color = Palette.accent,
                        )
                    }
                }

                TextButton(onClick = onDiscard) {
                    Text(
                        text = "捨てて$verb",
                        color = Palette.rose,
                    )
                }

                TextButton(onClick = onKeep) {
                    Text(
                        text = "入力に戻る",
                        color = Palette.subtext,
                    )
                }
            }
        },
        title = {
            Text(
                text = "保存していない変更があります",
                color = Palette.text,
                style = textFont(
                    size = FontSize.Body,
                    weight = FontWeight.SemiBold,
                ),
            )
        },
        text = {
            Text(
                text = "入力した内容は、保存しないと残りません",
                color = Palette.subtext,
            )
        },
        containerColor = Palette.backgroundTop,
    )
}

private val typeOptions = listOf(
    Entry.Kind.expense to "支出",
    Entry.Kind.income to "収入",
    Entry.Kind.transfer to "振替",
)

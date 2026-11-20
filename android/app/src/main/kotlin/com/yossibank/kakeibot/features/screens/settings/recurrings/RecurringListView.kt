package com.yossibank.kakeibot.features.screens.settings.recurrings

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGesturesAfterLongPress
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.boundsInRoot
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.layout.positionInRoot
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.zIndex
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.setting.SettingsScreen
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.designsystem.components.input.SegmentSwitch
import com.yossibank.kakeibot.designsystem.components.modal.DeleteDialog
import com.yossibank.kakeibot.designsystem.components.row.SwipeRow
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsHeader
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsHintButton
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsIntroCard
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsIntroNote
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsScreenFlag
import com.yossibank.kakeibot.features.shared.settingsparts.SettingsUndoNotice
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.writes.types.Deletion
import kotlinx.coroutines.launch
import kotlin.math.roundToInt

private val rowSpacing = 12.dp

private sealed interface Editing {
    data object New : Editing

    data class Existing(
        val id: Identifier<Recurring>,
    ) : Editing
}

private class Lift {
    var id: Identifier<Recurring>? by mutableStateOf(null)
    var startY by mutableFloatStateOf(0f)
    var dragY by mutableFloatStateOf(0f)
    var pointer by mutableStateOf<Offset?>(null)
    var hideTarget by mutableStateOf<Rect?>(null)

    val isOverHide: Boolean
        get() {
            val pointer = pointer ?: return false
            return hideTarget?.contains(pointer) ?: false
        }
}

@Composable
fun RecurringListView(
    database: AppDatabase,
    today: LocalDate,
    onBack: () -> Unit,
    opening: Identifier<Recurring>? = null,
) {
    val model = remember(database, today) {
        RecurringListModel(
            database = database,
            today = today,
        )
    }

    val scope = rememberCoroutineScope()

    var editing by remember { mutableStateOf(opening?.let { Editing.Existing(it) } as Editing?) }
    var openId by remember { mutableStateOf<Identifier<Recurring>?>(null) }
    var hiddenId by remember { mutableStateOf<Identifier<Recurring>?>(null) }
    var deletion by remember { mutableStateOf<Deletion?>(null) }
    var deleting by remember { mutableStateOf<Identifier<Recurring>?>(null) }
    var isConfirmingDeleteHidden by remember { mutableStateOf(false) }

    val lift = remember { Lift() }
    val hint =
        remember(database) { SettingsScreenFlag.closedHint(SettingsScreen.recurrings, database) }
    val hiddenList =
        remember(database) {
            SettingsScreenFlag.openHiddenList(SettingsScreen.recurrings, database)
        }

    LaunchedEffect(hiddenList) {
        hiddenList.load()
    }

    LaunchedEffect(model) {
        model.observe()
    }

    BackHandler(onBack = onBack)

    fun hide(id: Identifier<Recurring>) {
        scope.launch {
            if (model.hide(id)) {
                hiddenId = id
            }
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
                .padding(
                    horizontal = 16.dp,
                    vertical = 12.dp,
                ),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            SettingsHeader(
                title = "固定費",
                isRoot = false,
                onBack = onBack,
            ) {
                SettingsHintButton(flag = hint)
            }

            SettingsIntroCard(
                icon = R.drawable.ic_repeat,
                headline = "決まった日の記録を" to "ひとりでに入れます",
                flag = hint,
                notes = buildList {
                    add(SettingsIntroNote(R.drawable.ic_calendar, "休日なら、前後の平日にずらせます"))
                    add(SettingsIntroNote(R.drawable.ic_bell, "前もって通知で知らせられます"))

                    if (model.rows.isNotEmpty()) {
                        add(SettingsIntroNote.arrange)
                        add(SettingsIntroNote.swipeDelete)
                    }
                },
            )

            SegmentSwitch(
                selection = model.type,
                options = typeOptions,
                onSelect = {
                    openId = null
                    model.type = it
                },
                modifier = Modifier.fillMaxWidth(),
            )

            Column(
                modifier = Modifier
                    .weight(1f)
                    .verticalScroll(
                        state = rememberScrollState(),
                        enabled = lift.id == null,
                    ),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                if (model.rows.isEmpty()) {
                    EmptyNote(text = model.emptyText)
                } else {
                    TotalCard(
                        type = model.type,
                        total = model.monthTotal,
                    )
                }

                Board(
                    model = model,
                    lift = lift,
                    openId = openId,
                    onOpen = { openId = it },
                    onEdit = { editing = Editing.Existing(it) },
                    onHide = ::hide,
                    onDelete = { deleting = it },
                )

                if (model.hiddenRows.isNotEmpty()) {
                    HiddenSection(
                        model = model,
                        isOpen = hiddenList.isOn,
                        onToggle = { scope.launch { hiddenList.set(!hiddenList.isOn) } },
                        onDeleteAll = { isConfirmingDeleteHidden = true },
                        onEdit = { editing = Editing.Existing(it) },
                        onShow = { id -> scope.launch { model.show(id) } },
                    )
                }
            }

            if (lift.id != null) {
                HideTarget(lift = lift)
            } else {
                AddButton(
                    title = "${typeName(model.type)}の固定費を追加",
                    onSelect = { editing = Editing.New },
                )
            }
        }

        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .navigationBarsPadding()
                .padding(
                    start = 16.dp,
                    end = 16.dp,
                    bottom = 84.dp,
                ),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            hiddenId?.let { id ->
                SettingsUndoNotice(
                    message = "止めて非表示にしました",
                    icon = R.drawable.ic_pause,
                    onUndo = { scope.launch { model.show(id) } },
                    onClose = { hiddenId = null },
                )
            }

            deletion?.let { current ->
                SettingsUndoNotice(
                    message = "削除しました",
                    icon = R.drawable.ic_trash,
                    onUndo = { scope.launch { model.restore(current) } },
                    onClose = { deletion = null },
                )
            }

            if (model.message.isNotEmpty()) {
                Text(
                    text = model.message,
                    modifier = Modifier
                        .fillMaxWidth()
                        .card()
                        .clickable(onClick = model::clearMessage)
                        .padding(12.dp),
                    color = Palette.rose,
                    style = textFont(style = FontTextStyle.Caption),
                )
            }
        }

        AnimatedVisibility(
            visible = editing != null,
            enter = slideInHorizontally { it },
            exit = slideOutHorizontally { it },
        ) {
            val current = remember { editing }

            if (current != null) {
                RecurringEditView(
                    database = database,
                    today = today,
                    type = model.type,
                    editingId = (current as? Editing.Existing)?.id,
                    onClose = { editing = null },
                    onDelete = { deletion = it },
                    onHide = { hiddenId = (current as? Editing.Existing)?.id },
                )
            }
        }
    }

    deleting?.let { id ->
        DeleteDialog(
            title = "この固定費を削除しますか",
            message = "これまでに作った記録は残ります",
            onConfirm = {
                deleting = null
                scope.launch { deletion = model.delete(id) }
            },
            onDismiss = { deleting = null },
        )
    }

    if (isConfirmingDeleteHidden) {
        DeleteDialog(
            title = "非表示の固定費をまとめて削除しますか",
            message = "これまでに作った記録は残ります",
            onConfirm = {
                isConfirmingDeleteHidden = false
                scope.launch { deletion = model.deleteHidden() }
            },
            onDismiss = { isConfirmingDeleteHidden = false },
        )
    }
}

@Composable
private fun Board(
    model: RecurringListModel,
    lift: Lift,
    openId: Identifier<Recurring>?,
    onOpen: (Identifier<Recurring>?) -> Unit,
    onEdit: (Identifier<Recurring>) -> Unit,
    onHide: (Identifier<Recurring>) -> Unit,
    onDelete: (Identifier<Recurring>) -> Unit,
) {
    val rows = model.rows
    val slot = with(LocalDensity.current) { (recurringRowHeight + rowSpacing).toPx() }
    var origin by remember { mutableStateOf(Offset.Zero) }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(recurringRowHeight * rows.size + rowSpacing * maxOf(rows.size - 1, 0))
            .onGloballyPositioned { origin = it.positionInRoot() },
    ) {
        rows.forEachIndexed { index, row ->
            key(row.id) {
                BoardRow(
                    model = model,
                    lift = lift,
                    row = row,
                    index = index,
                    slot = slot,
                    origin = origin,
                    openId = openId,
                    onOpen = onOpen,
                    onEdit = onEdit,
                    onHide = onHide,
                    onDelete = onDelete,
                )
            }
        }
    }
}

@Composable
private fun BoardRow(
    model: RecurringListModel,
    lift: Lift,
    row: RecurringRow,
    index: Int,
    slot: Float,
    origin: Offset,
    openId: Identifier<Recurring>?,
    onOpen: (Identifier<Recurring>?) -> Unit,
    onEdit: (Identifier<Recurring>) -> Unit,
    onHide: (Identifier<Recurring>) -> Unit,
    onDelete: (Identifier<Recurring>) -> Unit,
) {
    val scope = rememberCoroutineScope()
    val currentOrigin by rememberUpdatedState(origin)

    val isLifted = lift.id == row.id
    val target by animateDpAsState(
        targetValue = (recurringRowHeight + rowSpacing) * index,
        label = "recurring-row",
    )

    SwipeRow(
        id = row.id,
        openId = openId,
        onOpen = onOpen,
        onTap = { onEdit(row.id) },
        onHide = { onHide(row.id) },
        onDelete = { onDelete(row.id) },
        modifier = Modifier
            .zIndex(if (isLifted) 1f else 0f)
            .offset {
                val y = if (isLifted) lift.startY + lift.dragY else target.toPx()
                IntOffset(0, y.roundToInt())
            }.scale(if (isLifted) 1.03f else 1f),
        contentModifier = Modifier
            .pointerInput(row.id) {
                detectDragGesturesAfterLongPress(
                    onDragStart = { start ->
                        onOpen(null)
                        lift.id = row.id
                        lift.startY = model.rows.indexOfFirst { it.id == row.id } * slot
                        lift.dragY = 0f
                        lift.pointer = currentOrigin.copy(y = currentOrigin.y + lift.startY) + start
                    },
                    onDragEnd = {
                        val id = lift.id
                        val isHiding = lift.isOverHide
                        lift.id = null
                        lift.pointer = null

                        if (id != null && isHiding) {
                            model.cancelMoving()
                            onHide(id)
                        } else {
                            scope.launch { model.finishMoving() }
                        }
                    },
                    onDragCancel = {
                        lift.id = null
                        lift.pointer = null
                        model.cancelMoving()
                    },
                ) { change, amount ->
                    change.consume()
                    lift.dragY += amount.y
                    lift.pointer = lift.pointer?.plus(amount)

                    val position = ((lift.startY + lift.dragY) / slot).roundToInt()
                    model.move(row.id, to = position)
                }
            },
    ) {
        RecurringRowCard(row = row)
    }
}

@Composable
private fun HiddenSection(
    model: RecurringListModel,
    isOpen: Boolean,
    onToggle: () -> Unit,
    onDeleteAll: () -> Unit,
    onEdit: (Identifier<Recurring>) -> Unit,
    onShow: (Identifier<Recurring>) -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Row(
                    modifier = Modifier
                        .weight(1f)
                        .heightIn(min = 32.dp)
                        .clickable(onClick = onToggle),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(
                        painter = painterResource(R.drawable.ic_chevron_right),
                        contentDescription = null,
                        modifier = Modifier
                            .size(16.dp)
                            .rotate(if (isOpen) 90f else 0f),
                        tint = Palette.accent,
                    )

                    Text(
                        text = "非表示の固定費（${model.hiddenRows.size}）",
                        color = Palette.accent,
                        style = textFont(
                            style = FontTextStyle.Caption,
                            weight = FontWeight.SemiBold,
                        ),
                    )
                }

                if (isOpen) {
                    Row(
                        modifier = Modifier
                            .heightIn(min = 32.dp)
                            .clickable(onClick = onDeleteAll),
                        horizontalArrangement = Arrangement.spacedBy(4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(
                            painter = painterResource(R.drawable.ic_trash),
                            contentDescription = null,
                            modifier = Modifier.size(14.dp),
                            tint = Palette.rose,
                        )

                        Text(
                            text = "まとめて削除",
                            color = Palette.rose,
                            style = textFont(style = FontTextStyle.Caption),
                        )
                    }
                }
            }

            if (isOpen) {
                Text(
                    text = "長押しで上に動かすと戻せます",
                    color = Palette.subtext,
                    style = textFont(style = FontTextStyle.Caption2),
                )
            }
        }

        if (isOpen) {
            model.hiddenRows.forEach { row ->
                HiddenRow(
                    row = row,
                    onEdit = { onEdit(row.id) },
                    onShow = { onShow(row.id) },
                )
            }
        }
    }
}

@Composable
private fun HiddenRow(
    row: RecurringRow,
    onEdit: () -> Unit,
    onShow: () -> Unit,
) {
    var dragY by remember { mutableFloatStateOf(0f) }
    val reach = with(LocalDensity.current) { recurringRowHeight.toPx() }

    RecurringRowCard(
        row = row,
        isPaused = true,
        modifier = Modifier
            .zIndex(if (dragY != 0f) 1f else 0f)
            .offset { IntOffset(0, dragY.roundToInt()) }
            .alpha(if (dragY != 0f) 1f else 0.5f)
            .clickable(onClick = onEdit)
            .pointerInput(row.id) {
                detectDragGesturesAfterLongPress(
                    onDragEnd = {
                        if (dragY < -reach) {
                            onShow()
                        }

                        dragY = 0f
                    },
                    onDragCancel = { dragY = 0f },
                ) { change, amount ->
                    change.consume()
                    dragY = minOf(dragY + amount.y, 0f)
                }
            },
    )
}

@Composable
private fun HideTarget(lift: Lift) {
    val fill = if (lift.isOverHide) Palette.amber else Palette.amber.opacity(Emphasis.Soft)
    val text = if (lift.isOverHide) Palette.backgroundTop else Palette.amber

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(52.dp)
            .clip(CircleShape)
            .background(fill)
            .onGloballyPositioned { lift.hideTarget = it.boundsInRoot() },
        horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            painter = painterResource(R.drawable.ic_pause),
            contentDescription = null,
            modifier = Modifier.size(20.dp),
            tint = text,
        )

        Text(
            text = "ここで離すと止めて非表示",
            color = text,
            style = textFont(
                size = FontSize.Body,
                weight = FontWeight.SemiBold,
            ),
        )
    }
}

@Composable
private fun TotalCard(
    type: Entry.Kind,
    total: Long,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .card()
            .padding(vertical = 16.dp),
        verticalArrangement = Arrangement.spacedBy(4.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = "今月の${typeName(type)}",
            color = Palette.accent,
            style = textFont(style = FontTextStyle.Caption2),
        )

        AmountText(
            amount = total.coerceAtMost(Int.MAX_VALUE.toLong()).toInt(),
            style = displayFont(size = FontSize.Headline),
            color = Palette.accentStrong,
        )
    }
}

@Composable
private fun EmptyNote(text: String) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .card()
            .padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(
            painter = painterResource(R.drawable.ic_repeat),
            contentDescription = null,
            modifier = Modifier.size(28.dp),
            tint = Palette.accent,
        )

        Text(
            text = text,
            color = Palette.subtext,
            style = textFont(style = FontTextStyle.Subheadline),
        )
    }
}

@Composable
private fun AddButton(
    title: String,
    onSelect: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(52.dp)
            .clip(CircleShape)
            .background(Brush.verticalGradient(listOf(Palette.accentDeep, Palette.accent)))
            .clickable(onClick = onSelect),
        horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            painter = painterResource(R.drawable.ic_add),
            contentDescription = null,
            modifier = Modifier.size(20.dp),
            tint = Palette.backgroundTop,
        )

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

private fun typeName(type: Entry.Kind): String = when (type) {
    Entry.Kind.expense -> "支出"
    Entry.Kind.income -> "収入"
    Entry.Kind.transfer -> "振替"
}

private val typeOptions = listOf(
    Entry.Kind.expense to "支出",
    Entry.Kind.income to "収入",
    Entry.Kind.transfer to "振替",
)

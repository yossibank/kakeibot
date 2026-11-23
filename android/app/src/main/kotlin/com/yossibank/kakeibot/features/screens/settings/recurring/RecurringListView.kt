package com.yossibank.kakeibot.features.screens.settings.recurring

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
import androidx.compose.runtime.SideEffect
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
import com.yossibank.kakeibot.core.concepts.entry.title
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.setting.SettingsScreen
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.designsystem.components.button.PrimaryButton
import com.yossibank.kakeibot.designsystem.components.input.SegmentSwitch
import com.yossibank.kakeibot.designsystem.components.modal.DeleteDialog
import com.yossibank.kakeibot.designsystem.components.modal.UndoNoticeState
import com.yossibank.kakeibot.designsystem.components.row.SwipeRow
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.components.text.clamped
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Metrics
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.features.shared.entrylist.rememberEntryList
import com.yossibank.kakeibot.features.shared.settingsparts.board.SettingsUndoNotice
import com.yossibank.kakeibot.features.shared.settingsparts.hint.SettingsHintButton
import com.yossibank.kakeibot.features.shared.settingsparts.hint.SettingsIntroCard
import com.yossibank.kakeibot.features.shared.settingsparts.hint.SettingsIntroNote
import com.yossibank.kakeibot.features.shared.settingsparts.hint.SettingsScreenFlag
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsFrame
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsHeader
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.writes.types.Deletion
import kotlinx.coroutines.launch
import kotlin.math.roundToInt

private sealed interface Editing {
    data object New : Editing

    data class Existing(
        val id: Identifier<Recurring>,
    ) : Editing
}

private sealed interface DeleteTarget {
    data object AllHidden : DeleteTarget

    data class One(
        val id: Identifier<Recurring>,
    ) : DeleteTarget
}

@Composable
fun RecurringListView(
    database: AppDatabase,
    today: LocalDate,
    onBack: () -> Unit,
    opening: Identifier<Recurring>? = null,
) {
    val entryList = rememberEntryList(database)

    val model = remember(database, entryList) {
        RecurringListModel(
            database = database,
            entryList = entryList,
            today = today,
        )
    }

    SideEffect {
        model.today = today
    }

    val scope = rememberCoroutineScope()

    var editing by remember { mutableStateOf(opening?.let { Editing.Existing(it) } as Editing?) }
    var openId by remember { mutableStateOf<Identifier<Recurring>?>(null) }
    var deleting by remember { mutableStateOf<DeleteTarget?>(null) }

    val hiddenNotice = remember { UndoNoticeState<Identifier<Recurring>>() }
    val deletedNotice = remember { UndoNoticeState<Deletion>() }
    val lift = remember { RecurringLift() }
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

    hiddenNotice.Timer()
    deletedNotice.Timer()

    BackHandler(onBack = onBack)

    fun hide(id: Identifier<Recurring>) {
        scope.launch {
            if (model.hide(id)) {
                hiddenNotice.show(id)
            }
        }
    }

    val actions = RecurringRowActions(
        onOpen = { openId = it },
        onEdit = { editing = Editing.Existing(it) },
        onHide = ::hide,
        onDelete = { deleting = DeleteTarget.One(it) },
    )

    SettingsFrame(
        title = "固定費",
        isRoot = false,
        onBack = onBack,
        trailing = { SettingsHintButton(flag = hint) },
        overlay = {
            Column(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .navigationBarsPadding()
                    .padding(
                        start = 16.dp,
                        end = 16.dp,
                        bottom = Metrics.noticeLift,
                    ),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                hiddenNotice.current?.let { id ->
                    SettingsUndoNotice(
                        message = "止めて非表示にしました",
                        icon = R.drawable.ic_pause,
                        onUndo = { scope.launch { model.show(id) } },
                        onClose = hiddenNotice::dismiss,
                    )
                }

                deletedNotice.current?.let { current ->
                    SettingsUndoNotice(
                        message = "削除しました",
                        icon = R.drawable.ic_trash,
                        onUndo = { scope.launch { model.restore(current) } },
                        onClose = deletedNotice::dismiss,
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
                    RecurringEditSheet(
                        database = database,
                        today = today,
                        type = model.type,
                        editingId = (current as? Editing.Existing)?.id,
                        onClose = { editing = null },
                        onDelete = deletedNotice::show,
                        onHide = { (current as? Editing.Existing)?.id?.let(hiddenNotice::show) },
                    )
                }
            }
        },
    ) {
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

            RecurringBoard(
                model = model,
                lift = lift,
                openId = openId,
                actions = actions,
            )

            if (model.hiddenRows.isNotEmpty()) {
                RecurringHiddenSection(
                    rows = model.hiddenRows,
                    isOpen = hiddenList.isOn,
                    onToggle = { scope.launch { hiddenList.set(!hiddenList.isOn) } },
                    onDeleteAll = { deleting = DeleteTarget.AllHidden },
                    onEdit = actions.onEdit,
                    onShow = { id -> scope.launch { model.show(id) } },
                )
            }
        }

        if (lift.id != null) {
            RecurringHideTarget(lift = lift)
        } else {
            PrimaryButton(
                title = "${model.type.title}の固定費を追加",
                onClick = { editing = Editing.New },
                modifier = Modifier.fillMaxWidth(),
                icon = R.drawable.ic_add,
            )
        }
    }

    deleting?.let { target ->
        val isAll = target == DeleteTarget.AllHidden

        DeleteDialog(
            title = if (isAll) "非表示の固定費をまとめて削除しますか" else "この固定費を削除しますか",
            message = "これまでに作った記録は残ります",
            onConfirm = {
                deleting = null

                scope.launch {
                    val deletion = when (target) {
                        DeleteTarget.AllHidden -> model.deleteHidden()
                        is DeleteTarget.One -> model.delete(target.id)
                    }

                    deletion?.let(deletedNotice::show)
                }
            },
            onDismiss = { deleting = null },
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
            text = "今月の${type.title}",
            color = Palette.accent,
            style = textFont(style = FontTextStyle.Caption2),
        )

        AmountText(
            amount = total.clamped,
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

private val typeOptions = Entry.Kind.entries.map { it to it.title }

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
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
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
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.designsystem.components.button.PrimaryButton
import com.yossibank.kakeibot.designsystem.components.input.SegmentSwitch
import com.yossibank.kakeibot.designsystem.components.modal.DeleteDialog
import com.yossibank.kakeibot.designsystem.components.row.SwipeRow
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.theme.Emphasis
import com.yossibank.kakeibot.designsystem.theme.FontSize
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Metrics
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.displayFont
import com.yossibank.kakeibot.designsystem.theme.opacity
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.RecurringListModel
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.RecurringListModel.DeleteTarget
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.RecurringListModel.Editing
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.hiddenRows
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.rows
import com.yossibank.kakeibot.featuremodels.shared.amount.clamped
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenParts
import com.yossibank.kakeibot.featuremodels.shared.model.perform
import com.yossibank.kakeibot.featuremodels.shared.notice.DeletionNotice
import com.yossibank.kakeibot.features.shared.settingsparts.board.SettingsUndoNotice
import com.yossibank.kakeibot.features.shared.settingsparts.hint.SettingsHintButton
import com.yossibank.kakeibot.features.shared.settingsparts.hint.SettingsIntroCard
import com.yossibank.kakeibot.features.shared.settingsparts.hint.SettingsIntroNote
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsFrame
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsHeader
import kotlin.math.roundToInt

@Composable
fun RecurringListView(
    parts: ScreenParts,
    today: LocalDate,
    onBack: () -> Unit,
    opening: Identifier<Recurring>? = null,
) {
    val model = remember(parts) {
        RecurringListModel(
            parts = parts,
            today = today,
            opening = opening,
        )
    }

    SideEffect {
        model.state.today = today
    }

    val hiddenNotice = model.state.hidden
    val deletedNotice = model.state.deleted
    val lift = remember { RecurringLift() }

    LaunchedEffect(model) {
        model.loadFold(model.input.hiddenList)
    }

    LaunchedEffect(model) {
        model.observe()
    }

    model.state.task.Timer()

    hiddenNotice.Timer()
    deletedNotice.Timer()

    BackHandler(onBack = onBack)

    val actions = RecurringRowActions(
        onOpen = { model.state.openId = it },
        onEdit = { model.state.editing = Editing.Existing(it) },
        onHide = { id -> model.perform { it.hide(id) } },
        onDelete = { model.state.deleting = DeleteTarget.One(it) },
    )

    SettingsFrame(
        title = "固定費",
        isRoot = false,
        onBack = onBack,
        trailing = {
            SettingsHintButton(
                fold = model.input.hint,
                model = model,
            )
        },
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
                        onUndo = { model.perform { it.show(id) } },
                        onClose = hiddenNotice::dismiss,
                    )
                }

                deletedNotice.current?.let { current ->
                    SettingsUndoNotice(
                        message = DeletionNotice.message(current),
                        icon = R.drawable.ic_trash,
                        onUndo = { model.perform { it.restore(current) } },
                        onClose = deletedNotice::dismiss,
                    )
                }

                if (model.state.task.message.isNotEmpty()) {
                    Text(
                        text = model.state.task.message,
                        modifier = Modifier
                            .fillMaxWidth()
                            .card()
                            .clickable(onClick = model.state.task::clear)
                            .padding(12.dp),
                        color = Palette.rose,
                        style = textFont(style = FontTextStyle.Caption),
                    )
                }
            }

            AnimatedVisibility(
                visible = model.state.editing != null,
                enter = slideInHorizontally { it },
                exit = slideOutHorizontally { it },
            ) {
                val current = remember { model.state.editing }

                if (current != null) {
                    RecurringEditSheet(
                        parts = parts,
                        today = today,
                        type = model.state.type,
                        editingId = (current as? Editing.Existing)?.id,
                        onClose = { model.state.editing = null },
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
            fold = model.input.hint,
            model = model,
            notes = buildList {
                add(SettingsIntroNote(R.drawable.ic_calendar, "休日なら、前後の平日にずらせます"))
                add(SettingsIntroNote(R.drawable.ic_bell, "前もって通知で知らせられます"))

                if (model.output.rows.isNotEmpty()) {
                    add(SettingsIntroNote.arrange)
                    add(SettingsIntroNote.swipeDelete)
                }
            },
        )

        SegmentSwitch(
            selection = model.state.type,
            options = typeOptions,
            onSelect = model.state::select,
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
            if (model.output.rows.isEmpty()) {
                EmptyNote(text = model.output.emptyText)
            } else {
                TotalCard(
                    type = model.state.type,
                    total = model.output.monthTotal,
                )
            }

            RecurringBoard(
                model = model,
                lift = lift,
                openId = model.state.openId,
                actions = actions,
            )

            if (model.output.hiddenRows.isNotEmpty()) {
                RecurringHiddenSection(
                    rows = model.output.hiddenRows,
                    isOpen = model.input.hiddenList.isClosed != true,
                    onToggle = { model.perform { it.toggleHiddenList() } },
                    onDeleteAll = { model.state.deleting = DeleteTarget.AllHidden },
                    onEdit = actions.onEdit,
                    onShow = { id -> model.perform { it.show(id) } },
                )
            }
        }

        if (lift.id != null) {
            RecurringHideTarget(lift = lift)
        } else {
            PrimaryButton(
                title = "${model.state.type.title}の固定費を追加",
                onClick = { model.state.editing = Editing.New },
                modifier = Modifier.fillMaxWidth(),
                icon = R.drawable.ic_add,
            )
        }
    }

    model.state.deleting?.let { target ->
        val isAll = target == DeleteTarget.AllHidden

        DeleteDialog(
            title = if (isAll) "非表示の固定費をまとめて削除しますか" else "この固定費を削除しますか",
            message = "これまでに作った記録は残ります",
            onConfirm = {
                model.state.deleting = null

                model.perform {
                    when (target) {
                        DeleteTarget.AllHidden -> it.deleteHidden()
                        is DeleteTarget.One -> it.delete(target.id)
                    }
                }
            },
            onDismiss = { model.state.deleting = null },
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

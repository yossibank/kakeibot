package com.yossibank.kakeibot.features.screens.settings.recurring

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.title
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.designsystem.components.button.PrimaryButton
import com.yossibank.kakeibot.designsystem.components.input.SegmentSwitch
import com.yossibank.kakeibot.designsystem.components.modal.DeleteDialog
import com.yossibank.kakeibot.designsystem.components.surface.card
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Metrics
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.RecurringListModel
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.RecurringListModel.DeleteTarget
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.RecurringListModel.Editing
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.hiddenRows
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.rows
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenParts
import com.yossibank.kakeibot.featuremodels.shared.model.perform
import com.yossibank.kakeibot.featuremodels.shared.notice.DeletionNotice
import com.yossibank.kakeibot.features.shared.settingsparts.board.SettingsUndoNotice
import com.yossibank.kakeibot.features.shared.settingsparts.hint.SettingsHintButton
import com.yossibank.kakeibot.features.shared.settingsparts.hint.SettingsIntroCard
import com.yossibank.kakeibot.features.shared.settingsparts.hint.SettingsIntroNote
import com.yossibank.kakeibot.features.shared.settingsparts.layout.SettingsFrame

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

    val lift = remember { RecurringLift() }

    SideEffect {
        model.setToday(today)
    }

    LaunchedEffect(model) {
        model.loadFold(model.input.hiddenList)
    }

    LaunchedEffect(model) {
        model.observe()
    }

    BackHandler(onBack = onBack)

    val actions = RecurringRowActions(
        onOpen = model.state::open,
        onEdit = { model.state.presented.editing.show(Editing.Existing(it)) },
        onHide = { id -> model.perform { it.hide(id) } },
        onDelete = { model.state.presented.deleting.show(DeleteTarget.One(it)) },
    )

    RecurringListFrame(
        model = model,
        parts = parts,
        today = today,
        lift = lift,
        actions = actions,
        onBack = onBack,
    )

    DeleteConfirm(model = model)
}

@Composable
private fun RecurringListFrame(
    model: RecurringListModel,
    parts: ScreenParts,
    today: LocalDate,
    lift: RecurringLift,
    actions: RecurringRowActions,
    onBack: () -> Unit,
) {
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
            RecurringNotices(
                model = model,
                modifier = Modifier.align(Alignment.BottomCenter),
            )

            EditingSheet(
                model = model,
                parts = parts,
                today = today,
            )
        },
    ) {
        RecurringIntro(model = model)

        SegmentSwitch(
            selection = model.state.type,
            options = typeOptions,
            onSelect = model.state::select,
            modifier = Modifier.fillMaxWidth(),
        )

        RecurringContent(
            model = model,
            lift = lift,
            actions = actions,
            modifier = Modifier
                .weight(1f)
                .verticalScroll(
                    state = rememberScrollState(),
                    enabled = lift.id == null,
                ),
        )

        BottomAction(
            model = model,
            lift = lift,
        )
    }
}

@Composable
private fun RecurringNotices(
    model: RecurringListModel,
    modifier: Modifier = Modifier,
) {
    val hiddenNotice = model.state.notices.hidden
    val deletedNotice = model.state.notices.deleted

    Column(
        modifier = modifier
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

        if (model.state.notices.error.message.isNotEmpty()) {
            Text(
                text = model.state.notices.error.message,
                modifier = Modifier
                    .fillMaxWidth()
                    .card()
                    .clickable(onClick = model.state.notices.error::clear)
                    .padding(12.dp),
                color = Palette.rose,
                style = textFont(style = FontTextStyle.Caption),
            )
        }
    }
}

@Composable
private fun EditingSheet(
    model: RecurringListModel,
    parts: ScreenParts,
    today: LocalDate,
) {
    AnimatedVisibility(
        visible = model.state.presented.editing.current != null,
        enter = slideInHorizontally { it },
        exit = slideOutHorizontally { it },
    ) {
        val current = remember { model.state.presented.editing.current }

        if (current != null) {
            RecurringEditSheet(
                parts = parts,
                today = today,
                type = model.state.type,
                editingId = (current as? Editing.Existing)?.id,
                onClose = { model.state.presented.editing.close(current) },
                onDelete = model::receive,
                onHide = { (current as? Editing.Existing)?.id?.let(model::receiveHidden) },
            )
        }
    }
}

@Composable
private fun RecurringIntro(model: RecurringListModel) {
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
}

@Composable
private fun RecurringContent(
    model: RecurringListModel,
    lift: RecurringLift,
    actions: RecurringRowActions,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier,
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
            openId = model.state.presented.row.current,
            actions = actions,
        )

        if (model.output.hiddenRows.isNotEmpty()) {
            RecurringHiddenSection(
                rows = model.output.hiddenRows,
                isOpen = model.input.hiddenList.isClosed != true,
                onToggle = { model.perform { it.toggleHiddenList() } },
                onDeleteAll = { model.state.presented.deleting.show(DeleteTarget.AllHidden) },
                onEdit = actions.onEdit,
                onShow = { id -> model.perform { it.show(id) } },
            )
        }
    }
}

@Composable
private fun BottomAction(
    model: RecurringListModel,
    lift: RecurringLift,
) {
    if (lift.id != null) {
        RecurringHideTarget(lift = lift)
    } else {
        PrimaryButton(
            title = "${model.state.type.title}の固定費を追加",
            onClick = { model.state.presented.editing.show(Editing.New) },
            modifier = Modifier.fillMaxWidth(),
            icon = R.drawable.ic_add,
        )
    }
}

@Composable
private fun DeleteConfirm(model: RecurringListModel) {
    model.state.presented.deleting.current?.let { target ->
        val isAll = target == DeleteTarget.AllHidden

        DeleteDialog(
            title = if (isAll) "非表示の固定費をまとめて削除しますか" else "この固定費を削除しますか",
            message = "これまでに作った記録は残ります",
            onConfirm = {
                model.state.presented.deleting.close(target)

                model.perform {
                    when (target) {
                        DeleteTarget.AllHidden -> it.deleteHidden()
                        is DeleteTarget.One -> it.delete(target.id)
                    }
                }
            },
            onDismiss = { model.state.presented.deleting.close(target) },
        )
    }
}

private val typeOptions = Entry.Kind.entries.map { it to it.title }

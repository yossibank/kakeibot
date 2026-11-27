package com.yossibank.kakeibot.features.shared.notice

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.yossibank.kakeibot.R
import com.yossibank.kakeibot.designsystem.components.modal.UndoNotice
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.featuremodels.shared.model.perform
import com.yossibank.kakeibot.featuremodels.shared.notice.EntryNoticeModel
import com.yossibank.kakeibot.featuremodels.shared.notice.message

@Composable
fun EntryNoticeBanner(
    model: EntryNoticeModel,
    modifier: Modifier = Modifier,
) {
    when (val notice = model.state.notice) {
        is EntryNoticeModel.Notice.Changed -> {
            val isDeletion = notice.change.isDeletion

            UndoNotice(
                title = notice.message,
                icon = if (isDeletion) R.drawable.ic_trash else R.drawable.ic_check,
                modifier = modifier,
                tint = if (isDeletion) Palette.rose else Palette.accent,
                onTap = model::clearOnTap,
                onUndo = { model.perform { it.undo() } },
            )
        }

        EntryNoticeModel.Notice.Undone -> {
            UndoNotice(
                title = notice.message,
                icon = R.drawable.ic_repeat,
                modifier = modifier,
                onTap = model::clearOnTap,
            )
        }

        is EntryNoticeModel.Notice.Failed -> {
            UndoNotice(
                title = notice.message,
                icon = R.drawable.ic_close,
                modifier = modifier,
                tint = Palette.rose,
                onTap = model::clearOnTap,
            )
        }

        null -> {}
    }
}

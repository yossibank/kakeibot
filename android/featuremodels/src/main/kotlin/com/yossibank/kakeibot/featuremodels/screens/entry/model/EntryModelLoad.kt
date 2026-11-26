package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryItem
import com.yossibank.kakeibot.featuremodels.shared.model.ModelTask
import com.yossibank.kakeibot.store.writes.methods.EntryWriteError
import com.yossibank.kakeibot.store.writes.methods.EntryWriteException

fun EntryModel.close(): Boolean {
    if (output.isChanged) {
        state.presented.show(EntryModel.Presented.Discard)
        return false
    }

    return true
}

suspend fun EntryModel.recordAgain() {
    input.editingId = null
    input.original = null
    input.originalFee = null
    state.startAgain()

    if (output.wallets.none { it.id == state.form.walletId }) {
        setWallet(output.wallets.firstOrNull()?.id)
    }

    if (output.wallets.none { it.id == state.form.toWalletId }) {
        state.update { copy(toWalletId = null) }
    }

    if (state.form.type == Entry.Kind.transfer) {
        chooseDestination()
    } else if (output.categories.none { it.id == state.form.categoryId }) {
        state.update { withCategory(output.categories.firstOrNull()?.id) }
    }

    if (output.tags.none { it.id == state.form.tagId && it.archivedAt == null }) {
        state.update { copy(tagId = null) }
    }

    state.task.attempt(describe = ::describe) {
        loadHistory()
    }

    input.baseline = output.snapshot
    state.task.inform(RECORD_AGAIN_MESSAGE)
}

internal fun EntryModel.startNew() {
    state.update { withCategory(output.categories.firstOrNull()?.id) }
    setWallet(output.usualWalletId)
}

internal fun EntryModel.fill(
    entry: Entry,
    items: List<EntryItem.Draft>,
    fee: Int,
) {
    val form = EntryForm.of(
        entry = entry,
        items = items,
        offering = output.offeredCategories(of = entry.type, walletId = entry.walletId),
        allCategories = output.allCategories,
        allTags = output.allTags,
    )

    state.load(
        form = form,
        amount = entry.amount,
        fee = fee,
    )
}

internal fun EntryModel.describe(error: Exception): String {
    val isMissing = (error as? EntryWriteException)?.error == EntryWriteError.entryNotFound
    return if (isMissing) "記録が見つかりませんでした" else ModelTask.saveFailed
}

private const val RECORD_AGAIN_MESSAGE = "同じ内容で新しい記録にしました"

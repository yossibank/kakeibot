package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplate
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplateDraft
import com.yossibank.kakeibot.core.concepts.recurring.billMonth
import com.yossibank.kakeibot.core.concepts.recurring.cardBill

fun EntryModel.apply(template: EntryTemplate) {
    select(template.type)

    val tagId = output.allTags.firstOrNull { it.id == template.tagId && it.archivedAt == null }?.id

    val billMonth = input.cardBills
        .cardBill(paidBy = template.walletId)
        ?.billMonth(used = state.form.date, shift = template.billShift)

    state.update { withCategory(template.categoryId).copy(tagId = tagId) }
    setWallet(template.walletId)

    state.update {
        copy(
            memo = template.memo?.takeIf { it.isNotEmpty() } ?: memo,
            billMonth = billMonth,
            templateId = template.id,
        )
    }

    template.amount?.let(state::setAmount)

    state.focus(EntryModel.Field.Amount)
    state.task.clear()
}

fun EntryModel.applyRecent(entry: Entry) {
    output.wallet(of = entry.walletId)?.let { wallet ->
        setWallet(wallet.id)
    }

    val hasCategory = output.categories.any { it.id == entry.categoryId }
    val tagId = output.allTags.firstOrNull { it.id == entry.tagId && it.archivedAt == null }?.id

    state.update {
        copy(
            categoryId = if (hasCategory) entry.categoryId else categoryId,
            tagId = tagId,
            memo = entry.memo?.takeIf { it.isNotEmpty() } ?: memo,
        )
    }

    state.setAmount(entry.amount)
    state.focus(EntryModel.Field.Amount)
    state.task.clear()
}

fun EntryModel.applyTransfer(entry: Entry) {
    state.update {
        copy(
            walletId = entry.walletId,
            toWalletId = entry.toWalletId,
            billMonth = null,
        )
    }

    state.setAmount(entry.amount)
    state.setFee(output.fee(of = entry))
    state.focus(EntryModel.Field.Amount)
    state.task.clear()
}

fun EntryModel.Output.newTemplateDraft(): EntryTemplateDraft = EntryTemplateDraft(
    name = "",
    type = if (state.form.type == Entry.Kind.income) Entry.Kind.income else Entry.Kind.expense,
    amount = amount.takeIf { it > 0 },
    categoryId = state.form.categoryId,
    tagId = state.form.tagId,
    walletId = state.form.walletId,
    memo = state.form.memo,
)

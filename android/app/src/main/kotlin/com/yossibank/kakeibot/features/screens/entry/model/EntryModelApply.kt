package com.yossibank.kakeibot.features.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplate
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplateDraft
import com.yossibank.kakeibot.core.concepts.recurring.billMonth
import com.yossibank.kakeibot.core.concepts.recurring.cardBill

fun EntryModel.apply(template: EntryTemplate) {
    select(template.type)

    val tagId = allTags.firstOrNull { it.id == template.tagId && it.archivedAt == null }?.id

    val billMonth = cardBills
        .cardBill(paidBy = template.walletId)
        ?.billMonth(used = form.date, shift = template.billShift)

    update {
        copy(
            categoryId = template.categoryId,
            tagId = tagId,
            walletId = template.walletId,
            memo = template.memo?.takeIf { it.isNotEmpty() } ?: memo,
            billMonth = billMonth,
            templateId = template.id,
        )
    }

    template.amount?.let(::setAmount)

    focus(EntryModel.Field.Amount)
    clearMessage()
}

fun EntryModel.applyRecent(entry: Entry) {
    wallet(of = entry.walletId)?.let { wallet ->
        select(wallet = wallet)
    }

    val hasCategory = categories.any { it.id == entry.categoryId }
    val tagId = allTags.firstOrNull { it.id == entry.tagId && it.archivedAt == null }?.id

    update {
        copy(
            categoryId = if (hasCategory) entry.categoryId else categoryId,
            tagId = tagId,
            memo = entry.memo?.takeIf { it.isNotEmpty() } ?: memo,
        )
    }

    setAmount(entry.amount)
    focus(EntryModel.Field.Amount)
    clearMessage()
}

fun EntryModel.applyTransfer(entry: Entry) {
    update {
        copy(
            walletId = entry.walletId,
            toWalletId = entry.toWalletId,
            billMonth = null,
        )
    }

    setAmount(entry.amount)
    setFee(fee(of = entry))
    focus(EntryModel.Field.Amount)
    clearMessage()
}

fun EntryModel.newTemplateDraft(): EntryTemplateDraft = EntryTemplateDraft(
    name = "",
    type = if (form.type == Entry.Kind.income) Entry.Kind.income else Entry.Kind.expense,
    amount = amount.takeIf { it > 0 },
    categoryId = form.categoryId,
    tagId = form.tagId,
    walletId = form.walletId,
    memo = form.memo,
)

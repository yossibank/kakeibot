package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.category.EntryTag
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryDraft
import com.yossibank.kakeibot.core.concepts.entry.EntryItem
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplate
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier

data class EntryForm(
    val date: LocalDate,
    val type: Entry.Kind = Entry.Kind.expense,
    val categoryId: Identifier<EntryCategory>? = null,
    val tagId: Identifier<EntryTag>? = null,
    val walletId: Identifier<Wallet>? = null,
    val toWalletId: Identifier<Wallet>? = null,
    val memo: String = "",
    val billMonth: YearMonth? = null,
    val items: List<EntryItem.Draft> = emptyList(),
    val taxIncluded: Boolean = false,
    val templateId: Identifier<EntryTemplate>? = null,
    val categoryByType: Map<Entry.Kind, Identifier<EntryCategory>> = emptyMap(),
) {
    val store: String
        get() = memo.split("\n").first()

    fun withType(type: Entry.Kind): EntryForm {
        if (type == this.type) {
            return this
        }

        val leaving = categoryId

        return copy(
            type = type,
            categoryByType = if (leaving == null) {
                categoryByType - this.type
            } else {
                categoryByType + (this.type to leaving)
            },
        )
    }

    fun withWallet(id: Identifier<Wallet>?): EntryForm {
        if (id == walletId) {
            return this
        }

        return copy(
            walletId = id,
            billMonth = null,
        )
    }

    fun withWallet(
        id: Identifier<Wallet>?,
        offering: List<EntryCategory>,
        allCategories: List<EntryCategory>,
        allTags: List<EntryTag>,
    ): EntryForm {
        val moved = withWallet(id)
        val current = allCategories.firstOrNull { it.id == categoryId }

        if (id == walletId || current == null || offering.any { it.id == current.id }) {
            return moved
        }

        val tagName = allTags.firstOrNull { it.id == tagId }?.name
        val fitted = offering.firstOrNull { it.name == current.name } ?: offering.firstOrNull()

        val tag = allTags.firstOrNull { tag ->
            tag.categoryId == fitted?.id && tag.archivedAt == null && tag.name == tagName
        }

        return moved.copy(
            categoryId = fitted?.id,
            tagId = tag?.id,
        )
    }

    fun withCategory(id: Identifier<EntryCategory>?): EntryForm {
        if (id == categoryId) {
            return this
        }

        return copy(
            categoryId = id,
            tagId = null,
        )
    }

    fun withDate(date: LocalDate): EntryForm {
        if (date == this.date) {
            return this
        }

        return copy(
            date = date,
            billMonth = null,
        )
    }

    fun withStore(store: String): EntryForm {
        val lines = memo.split("\n").toMutableList()
        lines[0] = store.replace("\n", " ")
        return copy(memo = lines.joinToString("\n"))
    }

    fun draft(
        amount: Int,
        fee: Int,
        templates: List<EntryTemplate>,
        includesItems: Boolean,
        hasBillChoices: Boolean,
    ): EntryDraft? {
        val walletId = walletId ?: return null
        val template = templates.firstOrNull { it.id == templateId && it.type == type }

        return EntryDraft(
            type = type,
            amount = amount,
            date = date,
            categoryId = categoryId,
            tagId = tagId,
            templateId = template?.id,
            walletId = walletId,
            toWalletId = toWalletId,
            memo = memo,
            billMonth = if (hasBillChoices) billMonth else null,
            fee = fee,
            items = if (includesItems) items else emptyList(),
            taxIncluded = taxIncluded,
        )
    }

    fun cleared(): EntryForm = copy(
        tagId = null,
        memo = "",
        billMonth = null,
        items = emptyList(),
        taxIncluded = false,
        templateId = null,
    )

    companion object {
        fun of(
            entry: Entry,
            items: List<EntryItem.Draft>,
            offering: List<EntryCategory>,
            allCategories: List<EntryCategory>,
            allTags: List<EntryTag>,
        ): EntryForm {
            val form = EntryForm(
                date = entry.date,
                type = entry.type,
                categoryId = entry.categoryId,
                tagId = entry.tagId,
                toWalletId = entry.toWalletId,
                memo = entry.memo ?: "",
                items = items,
                taxIncluded = entry.taxIncluded,
                templateId = entry.templateId,
            )

            val fitted = form.withWallet(
                id = entry.walletId,
                offering = offering,
                allCategories = allCategories,
                allTags = allTags,
            )

            return fitted.copy(billMonth = entry.billMonth)
        }
    }
}

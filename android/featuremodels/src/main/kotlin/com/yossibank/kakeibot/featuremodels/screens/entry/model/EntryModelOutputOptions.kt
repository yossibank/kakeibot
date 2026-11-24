package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.category.EntryTag
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryDraft
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplate
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.featuremodels.shared.model.ModelTask

val EntryModel.Output.templates: List<EntryTemplate>
    get() = input.allTemplates.filter { it.type == state.form.type }

val EntryModel.Output.tags: List<EntryTag>
    get() = allTags.filter { tag ->
        tag.categoryId == state.form.categoryId &&
            (tag.archivedAt == null || tag.id == state.form.tagId)
    }

val EntryModel.Output.categories: List<EntryCategory>
    get() = when (state.form.type) {
        Entry.Kind.expense -> input.options?.expenseCategories ?: emptyList()
        Entry.Kind.income -> input.options?.incomeCategories ?: emptyList()
        Entry.Kind.transfer -> emptyList()
    }

val EntryModel.Output.wallets: List<Wallet>
    get() = input.options?.wallets ?: emptyList()

val EntryModel.Output.category: EntryCategory?
    get() = categories.firstOrNull { it.id == state.form.categoryId }

val EntryModel.Output.wallet: Wallet?
    get() = wallets.firstOrNull { it.id == state.form.walletId }

val EntryModel.Output.toWallet: Wallet?
    get() = wallets.firstOrNull { it.id == state.form.toWalletId }

internal val EntryModel.Output.usualWalletId: Identifier<Wallet>?
    get() {
        val type = state.form.type

        val recent = input.history?.entries.orEmpty()
            .filter { it.type == type && type != Entry.Kind.transfer && it.transferId == null }
            .maxByOrNull { it.createdAt }
            ?.walletId

        return if (wallets.any { it.id == recent }) recent else wallets.firstOrNull()?.id
    }

internal val EntryModel.Output.allTags: List<EntryTag>
    get() = (input.options?.tags ?: emptyList()) + (input.options?.sharedTags ?: emptyList())

internal val EntryModel.Output.draft: EntryDraft?
    get() = state.form.draft(
        amount = amount,
        fee = fee,
        templates = input.allTemplates,
        includesItems = showsItems,
    )

private val EntryModel.Output.allCategories: List<EntryCategory>
    get() = (input.options?.expenseCategories ?: emptyList()) +
        (input.options?.incomeCategories ?: emptyList()) +
        (input.options?.sharedCategories ?: emptyList())

fun EntryModel.Output.icon(of: Identifier<Icon>): Icon? = input.options?.icons?.get(of)

fun EntryModel.Output.category(of: Identifier<EntryCategory>?): EntryCategory? =
    allCategories.firstOrNull { it.id == of }

fun EntryModel.Output.wallet(of: Identifier<Wallet>?): Wallet? = wallets.firstOrNull { it.id == of }

internal fun EntryModel.Output.message(of: EntryDraft.Problem): String = when (of) {
    EntryDraft.Problem.amountNotPositive -> "金額を入れてください"
    EntryDraft.Problem.missingCategory -> "カテゴリを選んでください"
    EntryDraft.Problem.missingDestination -> "振替先を選んでください"
    EntryDraft.Problem.sameWallet -> "振替元と振替先を別にしてください"
    else -> ModelTask.saveFailed
}

package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.category.EntryTag
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryDraft
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplate
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.billChoiceCount
import com.yossibank.kakeibot.core.concepts.recurring.billDates
import com.yossibank.kakeibot.core.concepts.recurring.cardBill
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
    get() = categories(of = state.form.type, walletId = state.form.walletId)

val EntryModel.Output.isChanged: Boolean
    get() = input.baseline?.let { it != snapshot } ?: false

val EntryModel.Output.wallets: List<Wallet>
    get() {
        val wallets = input.options?.wallets ?: emptyList()

        if (!isEditing) {
            return wallets
        }

        val kept = listOfNotNull(state.form.walletId, state.form.toWalletId)
            .filter { id -> wallets.none { it.id == id } }
            .mapNotNull { input.history?.wallets?.get(it) }

        return (wallets + kept).sortedBy { it.sortOrder }
    }

val EntryModel.Output.category: EntryCategory?
    get() = categories.firstOrNull { it.id == state.form.categoryId }

val EntryModel.Output.wallet: Wallet?
    get() = wallets.firstOrNull { it.id == state.form.walletId }

val EntryModel.Output.toWallet: Wallet?
    get() = wallets.firstOrNull { it.id == state.form.toWalletId }

fun EntryModel.Output.icon(of: Identifier<Icon>): Icon? = input.options?.icons?.get(of)

fun EntryModel.Output.category(of: Identifier<EntryCategory>?): EntryCategory? =
    allCategories.firstOrNull { it.id == of }

fun EntryModel.Output.wallet(of: Identifier<Wallet>?): Wallet? = wallets.firstOrNull { it.id == of }

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
        hasBillChoices = hasBillChoices,
    )

internal val EntryModel.Output.billRecurring: Recurring?
    get() {
        val walletId = state.form.walletId

        if (state.form.type == Entry.Kind.transfer || walletId == null) {
            return null
        }

        return input.cardBills.cardBill(paidBy = walletId)
    }

internal val EntryModel.Output.hasBillChoices: Boolean
    get() {
        val dates = billRecurring?.billDates(
            used = state.form.date,
            count = Recurring.billChoiceCount,
        )

        return !dates.isNullOrEmpty()
    }

internal val EntryModel.Output.snapshot: EntryModel.Snapshot
    get() = EntryModel.Snapshot(
        form = state.form.copy(
            templateId = null,
            categoryByType = emptyMap(),
        ),
        calculator = state.calculator,
        feeCalculator = state.feeCalculator,
    )

internal val EntryModel.Output.allCategories: List<EntryCategory>
    get() = (input.options?.expenseCategories ?: emptyList()) +
        (input.options?.incomeCategories ?: emptyList()) +
        (input.options?.sharedCategories ?: emptyList())

internal fun EntryModel.Output.categories(
    of: Entry.Kind,
    walletId: Identifier<Wallet>?,
): List<EntryCategory> {
    val offered = offeredCategories(of = of, walletId = walletId)

    if (!isEditing) {
        return offered
    }

    val kept = setOfNotNull(state.form.categoryId, state.form.categoryByType[of])
        .mapNotNull { input.history?.categories?.get(it) }
        .filter { category ->
            category.kind.rawValue == of.rawValue && offered.none { it.id == category.id }
        }

    return (offered + kept).sortedBy { it.sortOrder }
}

internal fun EntryModel.Output.offeredCategories(
    of: Entry.Kind,
    walletId: Identifier<Wallet>?,
): List<EntryCategory> = when (of) {
    Entry.Kind.expense -> offeredCategories(of = EntryCategory.Kind.expense, walletId = walletId)
    Entry.Kind.income -> offeredCategories(of = EntryCategory.Kind.income, walletId = walletId)
    Entry.Kind.transfer -> emptyList()
}

internal fun EntryModel.Output.message(of: EntryDraft.Problem): String = when (of) {
    EntryDraft.Problem.amountNotPositive -> "金額を入れてください"
    EntryDraft.Problem.missingCategory -> "カテゴリを選んでください"
    EntryDraft.Problem.missingDestination -> "振替先を選んでください"
    EntryDraft.Problem.sameWallet -> "振替元と振替先を別にしてください"
    else -> ModelTask.saveFailed
}

private fun EntryModel.Output.offeredCategories(
    of: EntryCategory.Kind,
    walletId: Identifier<Wallet>?,
): List<EntryCategory> {
    val shared = (input.options?.sharedCategories ?: emptyList()).filter { category ->
        category.walletId != null && category.walletId == walletId
    }

    if (shared.isNotEmpty()) {
        return shared.filter { it.kind == of }
    }

    return when (of) {
        EntryCategory.Kind.expense -> input.options?.expenseCategories ?: emptyList()
        EntryCategory.Kind.income -> input.options?.incomeCategories ?: emptyList()
    }
}

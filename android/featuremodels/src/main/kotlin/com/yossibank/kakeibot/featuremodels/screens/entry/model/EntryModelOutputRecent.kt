package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.featuremodels.shared.amount.FeeChoiceRow

const val RECENT_ENTRY_LIMIT = 3
const val RECENT_TRANSFER_LIMIT = 3

val EntryModel.Output.recentEntries: List<Entry>
    get() {
        if (state.form.type == Entry.Kind.transfer) {
            return emptyList()
        }

        val shown = categories.map { it.id }.toSet()

        val seen = templates
            .map { recentKey(categoryId = it.categoryId, amount = it.amount, memo = it.memo) }
            .toMutableSet()

        return (input.history?.entries ?: emptyList())
            .filter { entry ->
                entry.type == state.form.type &&
                    entry.recurringId == null &&
                    entry.transferId == null &&
                    entry.categoryId in shown
            }.sortedByDescending { it.createdAt }
            .filter { entry ->
                seen.add(
                    recentKey(
                        categoryId = entry.categoryId,
                        amount = entry.amount,
                        memo = entry.memo,
                    ),
                )
            }.take(RECENT_ENTRY_LIMIT)
    }

val EntryModel.Output.recentTransfers: List<Entry>
    get() {
        if (state.form.type != Entry.Kind.transfer) {
            return emptyList()
        }

        val shown = wallets.map { it.id }.toSet()
        val fees = feesByTransfer
        val seen = mutableSetOf<String>()

        return (input.history?.entries ?: emptyList())
            .filter { entry ->
                entry.type == Entry.Kind.transfer &&
                    entry.recurringId == null &&
                    entry.walletId in shown &&
                    entry.toWalletId in shown
            }.sortedByDescending { it.createdAt }
            .filter { entry ->
                seen.add(
                    "${entry.walletId}>${entry.toWalletId}>${entry.amount}>${fees[entry.id] ?: 0}",
                )
            }.take(RECENT_TRANSFER_LIMIT)
    }

val EntryModel.Output.feeChoices: List<Int>
    get() {
        val used = (input.history?.entries ?: emptyList())
            .filter { it.transferId != null }
            .sortedByDescending { it.createdAt }
            .map { it.amount }

        return (used + FeeChoiceRow.defaultChoices)
            .distinct()
            .take(FeeChoiceRow.defaultChoices.size)
    }

fun EntryModel.Output.fee(of: Entry): Int = (input.history?.entries ?: emptyList())
    .firstOrNull { it.transferId == of.id }
    ?.amount ?: 0

private val EntryModel.Output.feesByTransfer: Map<Identifier<Entry>, Int>
    get() = (input.history?.entries ?: emptyList())
        .mapNotNull { entry -> entry.transferId?.let { it to entry.amount } }
        .reversed()
        .toMap()

private fun recentKey(
    categoryId: Identifier<EntryCategory>?,
    amount: Int?,
    memo: String?,
): String = "${categoryId ?: ""}>${amount ?: ""}>${memo ?: ""}"

val EntryModel.Output.hasRecent: Boolean
    get() = if (state.form.type == Entry.Kind.transfer) {
        recentTransfers.isNotEmpty()
    } else {
        templates.isNotEmpty() || recentEntries.isNotEmpty()
    }

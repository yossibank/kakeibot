package com.yossibank.kakeibot.features.screens.entry.model

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.designsystem.components.row.FeeChoiceRow

const val RECENT_ENTRY_LIMIT = 3
const val RECENT_TRANSFER_LIMIT = 3

val EntryModel.recentEntries: List<Entry>
    get() {
        if (type == Entry.Kind.transfer) {
            return emptyList()
        }

        val shown = categories.map { it.id }.toSet()

        val seen = templates
            .map { recentKey(categoryId = it.categoryId, amount = it.amount, memo = it.memo) }
            .toMutableSet()

        return (history?.entries ?: emptyList())
            .filter { entry ->
                entry.type == type &&
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

val EntryModel.recentTransfers: List<Entry>
    get() {
        if (type != Entry.Kind.transfer) {
            return emptyList()
        }

        val shown = wallets.map { it.id }.toSet()
        val fees = feesByTransfer
        val seen = mutableSetOf<String>()

        return (history?.entries ?: emptyList())
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

val EntryModel.feeChoices: List<Int>
    get() {
        val used = (history?.entries ?: emptyList())
            .filter { it.transferId != null }
            .sortedByDescending { it.createdAt }
            .map { it.amount }

        return (used + FeeChoiceRow.defaultChoices)
            .distinct()
            .take(FeeChoiceRow.defaultChoices.size)
    }

fun EntryModel.fee(of: Entry): Int = (history?.entries ?: emptyList())
    .firstOrNull { it.transferId == of.id }
    ?.amount ?: 0

private val EntryModel.feesByTransfer: Map<Identifier<Entry>, Int>
    get() = (history?.entries ?: emptyList())
        .mapNotNull { entry -> entry.transferId?.let { it to entry.amount } }
        .reversed()
        .toMap()

private fun recentKey(
    categoryId: Identifier<EntryCategory>?,
    amount: Int?,
    memo: String?,
): String = "${categoryId ?: ""}>${amount ?: ""}>${memo ?: ""}"

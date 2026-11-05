package com.yossibank.kakeibot.core.concepts.entry

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.category.EntryTag
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier

data class EntryFilter(
    val categoryIds: Set<Identifier<EntryCategory>> = emptySet(),
    val walletIds: Set<Identifier<Wallet>> = emptySet(),
    val tagIds: Set<Identifier<EntryTag>> = emptySet(),
) {
    val isEmpty: Boolean
        get() = categoryIds.isEmpty() && walletIds.isEmpty() && tagIds.isEmpty()

    fun includes(entry: Entry): Boolean =
        includesCategory(entry) &&
            includesWallet(entry) &&
            includesTag(entry)

    fun apply(to: List<EntryDay>): List<EntryDay> {
        if (isEmpty) {
            return to
        }

        return to.filtered(::includes)
    }

    private fun includesCategory(entry: Entry): Boolean {
        if (categoryIds.isEmpty()) {
            return true
        }

        val categoryId = entry.categoryId ?: return false

        return categoryId in categoryIds
    }

    private fun includesTag(entry: Entry): Boolean {
        if (tagIds.isEmpty()) {
            return true
        }

        val tagId = entry.tagId ?: return false

        return tagId in tagIds
    }

    private fun includesWallet(entry: Entry): Boolean {
        if (walletIds.isEmpty()) {
            return true
        }

        if (entry.walletId in walletIds) {
            return true
        }

        val toWalletId = entry.toWalletId ?: return false

        return toWalletId in walletIds
    }
}

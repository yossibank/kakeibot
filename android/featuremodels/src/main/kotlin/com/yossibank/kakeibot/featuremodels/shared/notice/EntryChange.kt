package com.yossibank.kakeibot.featuremodels.shared.notice

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryItem
import com.yossibank.kakeibot.core.concepts.entry.NoSpendDay
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.featuremodels.shared.amount.AmountText

data class EntryChange(
    val kind: Kind,
    val entry: Entry,
    val label: String,
    val fee: Entry? = null,
    val clearedNoSpendDays: List<NoSpendDay> = emptyList(),
    val items: List<EntryItem> = emptyList(),
) {
    sealed interface Kind {
        data object Recorded : Kind

        data class Edited(
            val previous: Entry,
            val previousFee: Entry?,
        ) : Kind

        data object Deleted : Kind
    }

    val isDeletion: Boolean
        get() = kind == Kind.Deleted

    val subject: String
        get() {
            if (!isDeletion) {
                return label
            }

            val memo = entry.memo
                ?.split('\n', '\r')
                ?.firstOrNull { it.isNotEmpty() }
                ?.trim()
                .orEmpty()

            if (memo.isNotEmpty()) {
                return memo
            }

            return label.ifEmpty { "記録" }
        }

    val amountText: String
        get() = AmountText.text(entry.amount)

    val predicate: String
        get() = "を$verb"

    val message: String
        get() = "$subject $amountText $predicate"

    private val verb: String
        get() = when (kind) {
            Kind.Recorded -> if (entry.type == Entry.Kind.transfer) "振り替えました" else "記録しました"
            is Kind.Edited -> "変えました"
            Kind.Deleted -> "消しました"
        }

    companion object {
        fun label(
            entry: Entry,
            category: (Identifier<EntryCategory>) -> EntryCategory?,
            wallet: (Identifier<Wallet>) -> Wallet?,
        ): String {
            if (entry.type != Entry.Kind.transfer) {
                return entry.categoryId?.let(category)?.name ?: ""
            }

            val from = wallet(entry.walletId)?.name ?: ""
            val to = entry.toWalletId?.let(wallet)?.name ?: ""

            return "$from → $to"
        }
    }
}

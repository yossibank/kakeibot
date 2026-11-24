package com.yossibank.kakeibot.featuremodels.shared.entrylist

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.queries.types.EntryList
import com.yossibank.kakeibot.store.queries.types.title

data class EntryRowItem(
    val id: Identifier<Entry>,
    val icon: Icon?,
    val title: String,
    val detail: String?,
    val memo: String?,
    val amount: Int,
    val type: Entry.Kind,
    val isRecurring: Boolean,
) {
    companion object {
        fun of(
            entry: Entry,
            list: EntryList,
            dayLabel: String? = null,
        ): EntryRowItem {
            val category = entry.categoryId?.let { list.categories[it] }

            return EntryRowItem(
                id = entry.id,
                icon = category?.let { list.icons[it.iconId] },
                title = list.title(of = entry),
                detail = listOfNotNull(
                    dayLabel,
                    detail(
                        entry = entry,
                        list = list,
                    ),
                ).joinToString("・").takeIf { it.isNotEmpty() },
                memo = entry.memo?.takeIf { it.isNotEmpty() },
                amount = entry.amount,
                type = entry.type,
                isRecurring = entry.recurringId != null,
            )
        }

        private fun detail(
            entry: Entry,
            list: EntryList,
        ): String? {
            val source = list.wallets[entry.walletId]?.name
            val destination = entry.toWalletId?.let { list.wallets[it]?.name }

            return if (destination != null) {
                "${source ?: ""} → $destination"
            } else {
                source
            }
        }
    }
}

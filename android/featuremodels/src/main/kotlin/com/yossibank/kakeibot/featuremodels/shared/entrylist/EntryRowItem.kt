package com.yossibank.kakeibot.featuremodels.shared.entrylist

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.billDate
import com.yossibank.kakeibot.core.concepts.recurring.billText
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.queries.types.EntryList
import com.yossibank.kakeibot.store.queries.types.title

data class EntryRowItem(
    val id: Identifier<Entry>,
    val icon: Icon?,
    val title: String,
    val tag: String?,
    val detail: String?,
    val route: Route?,
    val memo: String?,
    val amount: Int,
    val type: Entry.Kind,
    val isRecurring: Boolean,
) {
    data class Route(
        val source: String,
        val destination: String,
    ) {
        val text: String
            get() = "$source → $destination"
    }

    companion object {
        fun of(
            entry: Entry,
            list: EntryList,
            dayLabel: String? = null,
        ): EntryRowItem {
            val category = entry.categoryId?.let { list.categories[it] }

            val route = route(
                entry = entry,
                list = list,
            )

            val wallet = if (route == null) {
                walletText(
                    entry = entry,
                    list = list,
                )
            } else {
                null
            }

            val detail = listOfNotNull(dayLabel, wallet).joinToString("・")

            return EntryRowItem(
                id = entry.id,
                icon = category?.let { list.icons[it.iconId] },
                title = list.title(of = entry),
                tag = entry.tagId?.let { list.tags[it] }?.name,
                detail = detail.takeIf { it.isNotEmpty() },
                route = route,
                memo = entry.memo?.takeIf { it.isNotEmpty() },
                amount = entry.amount,
                type = entry.type,
                isRecurring = entry.recurringId != null,
            )
        }

        private fun walletText(
            entry: Entry,
            list: EntryList,
        ): String? {
            val bill = billText(
                entry = entry,
                list = list,
            ).orEmpty()

            return list.wallets[entry.walletId]?.let { it.name + bill }
        }

        private fun billText(
            entry: Entry,
            list: EntryList,
        ): String? {
            val month = entry.billMonth ?: return null

            val dates = list.cardBills
                .filter { it.toWalletId == entry.walletId && it.archivedAt == null }
                .mapNotNull { bill ->
                    bill.billDate(
                        used = entry.date,
                        month = month,
                    )
                }

            val date = dates.singleOrNull() ?: return "（${month.month}月払い）"

            return "（${Recurring.billText(paidOn = date)}）"
        }

        private fun route(
            entry: Entry,
            list: EntryList,
        ): Route? {
            val transfer = transfer(
                fee = entry,
                list = list,
            )

            if (transfer != null) {
                return route(
                    entry = transfer,
                    list = list,
                )?.let { it.copy(destination = "${it.destination} の手数料") }
            }

            if (entry.type != Entry.Kind.transfer) {
                return null
            }

            val source = list.wallets[entry.walletId] ?: return null
            val destination = entry.toWalletId?.let { list.wallets[it] } ?: return null

            return Route(
                source = source.name,
                destination = destination.name,
            )
        }

        private fun transfer(
            fee: Entry,
            list: EntryList,
        ): Entry? {
            val transferId = fee.transferId ?: return null

            return list.days
                .firstOrNull { it.date == fee.date }
                ?.entries
                ?.firstOrNull { it.id == transferId && it.type == Entry.Kind.transfer }
        }
    }
}

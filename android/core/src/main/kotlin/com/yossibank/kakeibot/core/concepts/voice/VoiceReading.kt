package com.yossibank.kakeibot.core.concepts.voice

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier

data class VoiceReading(
    val amount: Int? = null,
    val date: LocalDate? = null,
    val categoryId: Identifier<EntryCategory>? = null,
    val walletId: Identifier<Wallet>? = null,
    val memo: String? = null,
) {
    data class Choice(
        val categoryIndex: Int?,
        val walletIndex: Int?,
    )

    val count: Int
        get() = listOf(amount, date, categoryId, walletId, memo).count { it != null }

    val isEmpty: Boolean
        get() = count == 0

    companion object {
        fun of(
            text: String,
            today: LocalDate,
            categories: List<EntryCategory>,
            wallets: List<Wallet>,
            choice: Choice? = null,
        ): VoiceReading {
            val spoken = VoiceText(text)
            val date = spoken.date(today = today)
            val amount = spoken.amount(skipping = date?.range)

            val category = pick(
                items = categories,
                index = choice?.categoryIndex,
                spoken = spoken,
                name = { it.name },
            )

            val wallet = pick(
                items = wallets,
                index = choice?.walletIndex,
                spoken = spoken,
                name = { it.name },
            )

            val walletRange = wallet?.let { spoken.range(of = it.name) }
            val used = listOfNotNull(date?.range, amount?.range, walletRange)

            return VoiceReading(
                amount = amount?.value,
                date = date?.value,
                categoryId = category?.id,
                walletId = wallet?.id,
                memo = spoken.memo(removing = used),
            )
        }

        private fun <Item> pick(
            items: List<Item>,
            index: Int?,
            spoken: VoiceText,
            name: (Item) -> String,
        ): Item? {
            if (index != null && index in items.indices) {
                return items[index]
            }

            return items
                .filter { spoken.contains(name(it)) }
                .maxByOrNull { name(it).length }
        }
    }
}

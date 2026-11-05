package com.yossibank.kakeibot.core.concepts.entry

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.category.EntryTag
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import kotlinx.serialization.Serializable
import java.time.Instant

data class Entry(
    val id: Identifier<Entry> = Identifier(),
    val type: Kind,
    val amount: Int,
    val date: LocalDate,
    val categoryId: Identifier<EntryCategory>?,
    val tagId: Identifier<EntryTag>? = null,
    val templateId: Identifier<EntryTemplate>? = null,
    val walletId: Identifier<Wallet>,
    val toWalletId: Identifier<Wallet>? = null,
    val memo: String? = null,
    val recurringId: Identifier<Recurring>? = null,
    val recurringDate: LocalDate? = null,
    val billMonth: YearMonth? = null,
    val transferId: Identifier<Entry>? = null,
    val taxIncluded: Boolean = false,
    val createdAt: Instant,
    val updatedAt: Instant,
) {
    @Serializable
    enum class Kind(
        val rawValue: String,
    ) {
        expense("expense"),
        income("income"),
        transfer("transfer"),
        ;

        companion object {
            fun of(rawValue: String): Kind? = entries.firstOrNull { it.rawValue == rawValue }
        }
    }
}

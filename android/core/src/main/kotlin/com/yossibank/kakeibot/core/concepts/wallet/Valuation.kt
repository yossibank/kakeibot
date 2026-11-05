package com.yossibank.kakeibot.core.concepts.wallet

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.shared.Identifier
import java.time.Instant

data class Valuation(
    val id: Identifier<Valuation> = Identifier(),
    val walletId: Identifier<Wallet>,
    val date: LocalDate,
    val amount: Int,
    val createdAt: Instant,
    val updatedAt: Instant,
) {
    fun includes(entry: Entry): Boolean {
        if (entry.date == date) {
            return entry.createdAt <= createdAt
        }

        return entry.date < date
    }
}

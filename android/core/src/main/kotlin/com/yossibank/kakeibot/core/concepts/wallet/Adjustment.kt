package com.yossibank.kakeibot.core.concepts.wallet

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.shared.Identifier
import java.time.Instant

data class Adjustment(
    val id: Identifier<Adjustment> = Identifier(),
    val walletId: Identifier<Wallet>,
    val date: LocalDate,
    val amount: Int,
    val createdAt: Instant,
    val updatedAt: Instant,
)

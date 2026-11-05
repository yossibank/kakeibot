package com.yossibank.kakeibot.core.concepts.reward

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.shared.Identifier
import java.time.Instant

data class RewardLog(
    val id: Identifier<RewardLog> = Identifier(),
    val ruleId: Identifier<RewardRule>,
    val date: LocalDate,
    val amount: Int,
    val createdAt: Instant,
)

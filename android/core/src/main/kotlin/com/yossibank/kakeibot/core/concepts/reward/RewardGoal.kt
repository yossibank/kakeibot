package com.yossibank.kakeibot.core.concepts.reward

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.shared.Identifier
import java.time.Instant

data class RewardGoal(
    val id: Identifier<RewardGoal> = Identifier(),
    val name: String,
    val targetAmount: Int,
    val purchasedAt: Instant? = null,
    val entryId: Identifier<Entry>? = null,
    val createdAt: Instant,
    val updatedAt: Instant,
)

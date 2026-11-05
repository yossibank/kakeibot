package com.yossibank.kakeibot.core.concepts.reward

import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.shared.Identifier
import java.time.Instant

data class RewardRule(
    val id: Identifier<RewardRule> = Identifier(),
    val name: String,
    val amount: Int,
    val iconId: Identifier<Icon>,
    val isActive: Boolean,
    val sortOrder: Int,
    val createdAt: Instant,
    val updatedAt: Instant,
)

package com.yossibank.kakeibot.store.queries.types

import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.reward.RewardRule
import com.yossibank.kakeibot.core.shared.Identifier

data class RewardRuleList(
    val rules: List<RewardRule>,
    val icons: Map<Identifier<Icon>, Icon>,
    val totals: Map<Identifier<RewardRule>, Total> = emptyMap(),
) {
    data class Total(
        val count: Int,
        val amount: Long,
    )

    fun total(of: RewardRule): Total? = totals[of.id]
}

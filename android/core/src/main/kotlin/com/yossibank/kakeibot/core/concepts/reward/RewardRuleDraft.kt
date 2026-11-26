package com.yossibank.kakeibot.core.concepts.reward

import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.icon.IconDraft
import com.yossibank.kakeibot.core.shared.DraftProblem
import com.yossibank.kakeibot.core.shared.IconHoldingDraft
import com.yossibank.kakeibot.core.shared.Identifier
import java.time.Instant

data class RewardRuleDraft(
    val name: String,
    val amount: Int,
    override val icon: IconDraft,
) : IconHoldingDraft<RewardRule> {
    constructor(
        rule: RewardRule,
        icon: Icon,
    ) : this(
        name = rule.name,
        amount = rule.amount,
        icon = IconDraft(icon),
    )

    override fun newValue(
        iconId: Identifier<Icon>,
        sortOrder: Int,
        at: Instant,
    ): RewardRule = newRule(
        iconId = iconId,
        sortOrder = sortOrder,
        at = at,
    )

    override fun applied(
        to: RewardRule,
        at: Instant,
    ): RewardRule {
        validateProblems()

        return to.copy(
            name = trimmedName,
            amount = amount,
            updatedAt = at,
        )
    }

    override val problems: List<DraftProblem>
        get() {
            val nameProblems = if (trimmedName.isEmpty()) {
                listOf(
                    DraftProblem.emptyName,
                )
            } else {
                emptyList()
            }

            val amountProblems = if (amount > 0) emptyList() else listOf(DraftProblem.emptyAmount)

            return nameProblems + amountProblems + icon.problems
        }

    fun newRule(
        iconId: Identifier<Icon>,
        sortOrder: Int,
        at: Instant,
    ): RewardRule {
        validateProblems()

        return RewardRule(
            name = trimmedName,
            amount = amount,
            iconId = iconId,
            isActive = true,
            sortOrder = sortOrder,
            createdAt = at,
            updatedAt = at,
        )
    }

    private val trimmedName: String
        get() = name.trim()
}

package com.yossibank.kakeibot.core.concepts.reward

import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.icon.IconDraft
import com.yossibank.kakeibot.core.shared.DraftProblem
import com.yossibank.kakeibot.core.shared.DraftProblemException
import com.yossibank.kakeibot.core.shared.Identifier
import java.time.Instant

data class RewardRuleDraft(
    val name: String,
    val amount: Int,
    val icon: IconDraft,
) {
    constructor(
        rule: RewardRule,
        icon: Icon,
    ) : this(
        name = rule.name,
        amount = rule.amount,
        icon = IconDraft(icon),
    )

    val problems: List<DraftProblem>
        get() {
            val nameProblems = if (trimmedName.isEmpty()) listOf(DraftProblem.emptyName) else emptyList()
            val amountProblems = if (amount > 0) emptyList() else listOf(DraftProblem.emptyAmount)

            return nameProblems + amountProblems + icon.problems
        }

    private val trimmedName: String
        get() = name.trim()

    fun newIcon(at: Instant): Icon {
        validate()

        return icon.newIcon(at)
    }

    fun newRule(
        iconId: Identifier<Icon>,
        sortOrder: Int,
        at: Instant,
    ): RewardRule {
        validate()

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

    fun applied(
        to: Icon,
        at: Instant,
    ): Icon {
        validate()

        return icon.applied(
            to = to,
            at = at,
        )
    }

    fun applied(
        to: RewardRule,
        at: Instant,
    ): RewardRule {
        validate()

        return to.copy(
            name = trimmedName,
            amount = amount,
            updatedAt = at,
        )
    }

    private fun validate() {
        val problem = problems.firstOrNull() ?: return

        throw DraftProblemException(problem)
    }
}

package com.yossibank.kakeibot.core.concepts.reward

import com.yossibank.kakeibot.core.shared.DraftProblem
import com.yossibank.kakeibot.core.shared.DraftProblemException
import java.time.Instant

data class RewardGoalDraft(
    val name: String,
    val targetAmount: Int,
) {
    constructor(goal: RewardGoal) : this(
        name = goal.name,
        targetAmount = goal.targetAmount,
    )

    val problems: List<DraftProblem>
        get() {
            val nameProblems = if (trimmedName.isEmpty()) listOf(DraftProblem.emptyName) else emptyList()
            val amountProblems = if (targetAmount > 0) emptyList() else listOf(DraftProblem.emptyAmount)

            return nameProblems + amountProblems
        }

    private val trimmedName: String
        get() = name.trim()

    fun newGoal(at: Instant): RewardGoal {
        validate()

        return RewardGoal(
            name = trimmedName,
            targetAmount = targetAmount,
            createdAt = at,
            updatedAt = at,
        )
    }

    fun applied(
        to: RewardGoal,
        at: Instant,
    ): RewardGoal {
        validate()

        return to.copy(
            name = trimmedName,
            targetAmount = targetAmount,
            updatedAt = at,
        )
    }

    private fun validate() {
        val problem = problems.firstOrNull() ?: return

        throw DraftProblemException(problem)
    }
}

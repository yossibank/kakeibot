package com.yossibank.kakeibot.store.queries.types

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.reward.RewardBalance
import com.yossibank.kakeibot.core.concepts.reward.RewardGoal
import com.yossibank.kakeibot.core.concepts.reward.RewardLog
import com.yossibank.kakeibot.core.concepts.reward.RewardRule
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.core.shared.Percent
import java.time.Instant

data class RewardBank(
    val rules: List<RewardRule>,
    val icons: Map<Identifier<Icon>, Icon>,
    val logs: List<RewardLog>,
    val goals: List<RewardGoal>,
) {
    val balance: Long
        get() = RewardBalance.amount(
            logs = logs,
            goals = goals,
        )

    val activeRules: List<RewardRule>
        get() = rules.filter { it.isActive }

    val waitingGoals: List<RewardGoal>
        get() = goals
            .filter { it.purchasedAt == null }
            .sortedBy { it.createdAt }

    val boughtGoals: List<RewardGoal>
        get() = goals
            .filter { it.purchasedAt != null }
            .sortedByDescending { it.purchasedAt ?: Instant.MIN }

    fun rule(of: RewardLog): RewardRule? = rules.firstOrNull { it.id == of.ruleId }

    fun rules(on: LocalDate): List<RewardRule> {
        val achieved = logs(on = on).map { it.ruleId }.toSet()
        val hidden = rules.filter { !it.isActive && it.id in achieved }

        return activeRules + hidden
    }

    fun icon(of: RewardRule): Icon? = icons[of.iconId]

    fun remaining(to: RewardGoal): Long {
        val shortfall = to.targetAmount - balance

        return maxOf(shortfall, 0L)
    }

    fun progress(to: RewardGoal): Double {
        if (to.targetAmount <= 0) {
            return 0.0
        }

        val ratio = balance.toDouble() / to.targetAmount.toDouble()
        val nonNegative = maxOf(ratio, 0.0)

        return minOf(nonNegative, 1.0)
    }

    fun percent(to: RewardGoal): Int = Percent.floor(
        part = balance,
        of = to.targetAmount.toLong(),
    )

    fun logs(on: LocalDate): List<RewardLog> = logs.filter { it.date == on }

    fun total(on: LocalDate): Long = logs(on = on).sumOf { it.amount.toLong() }
}

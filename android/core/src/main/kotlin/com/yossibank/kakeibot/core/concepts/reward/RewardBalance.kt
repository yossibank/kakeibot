package com.yossibank.kakeibot.core.concepts.reward

object RewardBalance {
    fun amount(
        logs: List<RewardLog>,
        goals: List<RewardGoal>,
    ): Long {
        val saved = logs.sumOf { it.amount.toLong() }
        val bought = goals.filter { it.purchasedAt != null }
        val spent = bought.sumOf { it.targetAmount.toLong() }

        return saved - spent
    }
}

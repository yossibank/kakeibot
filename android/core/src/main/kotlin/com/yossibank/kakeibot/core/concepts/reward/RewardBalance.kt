package com.yossibank.kakeibot.core.concepts.reward

object RewardBalance {
    fun amount(
        logs: List<RewardLog>,
        goals: List<RewardGoal>,
    ): Int {
        val saved = logs.sumOf { it.amount }
        val bought = goals.filter { it.purchasedAt != null }
        val spent = bought.sumOf { it.targetAmount }

        return saved - spent
    }
}

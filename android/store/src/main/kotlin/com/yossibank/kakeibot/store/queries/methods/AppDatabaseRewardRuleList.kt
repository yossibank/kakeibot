package com.yossibank.kakeibot.store.queries.methods

import com.yossibank.kakeibot.core.concepts.reward.RewardRule
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.observation
import com.yossibank.kakeibot.store.database.read
import com.yossibank.kakeibot.store.queries.types.RewardRuleList
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.RewardLogTotal
import com.yossibank.kakeibot.store.records.rows.RewardRuleRecord
import com.yossibank.kakeibot.store.records.rows.rewardRule
import com.yossibank.kakeibot.store.records.values.fromDatabaseValue
import kotlinx.coroutines.flow.Flow

fun AppDatabase.rewardRuleListUpdates(): Flow<RewardRuleList> = observation(
    "reward_rule",
    "icon",
    "reward_log",
) {
    fetchRewardRuleList()
}

suspend fun AppDatabase.rewardRuleList(): RewardRuleList = read {
    fetchRewardRuleList()
}

internal suspend fun AppDatabase.fetchRewardRules(): List<RewardRule> = rewardRuleDao()
    .inOrder()
    .map { it.decoded(RewardRuleRecord::rewardRule) }

private suspend fun AppDatabase.fetchRewardRuleList(): RewardRuleList {
    val rules = fetchRewardRules()

    val totals = rewardLogDao()
        .totals()
        .map { it.decoded(RewardLogTotal::pair) }
        .toMap()

    return RewardRuleList(
        rules = rules,
        icons = fetchIcons(rules.map { it.iconId }),
        totals = totals,
    )
}

private fun RewardLogTotal.pair(): Pair<Identifier<RewardRule>, RewardRuleList.Total>? {
    val id = Identifier.fromDatabaseValue<RewardRule>(ruleId) ?: return null

    val total = RewardRuleList.Total(
        count = count,
        amount = amount,
    )

    return id to total
}

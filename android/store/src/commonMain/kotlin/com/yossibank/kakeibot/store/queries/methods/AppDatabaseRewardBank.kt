package com.yossibank.kakeibot.store.queries.methods

import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.observation
import com.yossibank.kakeibot.store.database.read
import com.yossibank.kakeibot.store.queries.types.RewardBank
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.RewardGoalRecord
import com.yossibank.kakeibot.store.records.rows.RewardLogRecord
import com.yossibank.kakeibot.store.records.rows.rewardGoal
import com.yossibank.kakeibot.store.records.rows.rewardLog
import kotlinx.coroutines.flow.Flow

fun AppDatabase.rewardBankUpdates(): Flow<RewardBank> = observation(
    "reward_rule",
    "icon",
    "reward_log",
    "reward_goal",
) {
    fetchRewardBank()
}

suspend fun AppDatabase.rewardBank(): RewardBank = read {
    fetchRewardBank()
}

private suspend fun AppDatabase.fetchRewardBank(): RewardBank {
    val rules = fetchRewardRules()

    val logs = rewardLogDao()
        .latestFirst()
        .map { it.decoded(RewardLogRecord::rewardLog) }

    val goals = rewardGoalDao()
        .all()
        .map { it.decoded(RewardGoalRecord::rewardGoal) }

    return RewardBank(
        rules = rules,
        icons = fetchIcons(rules.map { it.iconId }),
        logs = logs,
        goals = goals,
    )
}

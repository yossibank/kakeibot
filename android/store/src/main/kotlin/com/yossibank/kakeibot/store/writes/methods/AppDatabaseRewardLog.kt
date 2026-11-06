package com.yossibank.kakeibot.store.writes.methods

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.reward.RewardBalance
import com.yossibank.kakeibot.core.concepts.reward.RewardLog
import com.yossibank.kakeibot.core.concepts.reward.RewardRule
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.RewardGoalRecord
import com.yossibank.kakeibot.store.records.rows.RewardLogRecord
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.rows.rewardGoal
import com.yossibank.kakeibot.store.records.rows.rewardLog
import com.yossibank.kakeibot.store.records.values.databaseValue
import java.time.Instant

suspend fun AppDatabase.setReward(
    ruleId: Identifier<RewardRule>,
    isAchieved: Boolean,
    on: LocalDate,
    at: Instant,
) {
    write {
        val rule = findRewardRule(ruleId) ?: throw RewardRuleWriteException(RewardRuleWriteError.ruleNotFound)
        val key = ruleId.databaseValue
        val date = on.databaseValue

        if (!isAchieved) {
            val cleared = rewardLogDao()
                .on(
                    ruleId = key,
                    date = date,
                )
                .sumOf { it.amount.toLong() }

            val balance = currentRewardBalance()

            if (balance - cleared < 0) {
                throw RewardRuleWriteException(RewardRuleWriteError.shortOfBalance)
            }

            rewardLogDao().deleteOn(
                ruleId = key,
                date = date,
            )

            return@write
        }

        val saved = rewardLogDao().on(
            ruleId = key,
            date = date,
        )

        if (saved.isNotEmpty()) {
            return@write
        }

        if (!rule.isActive) {
            throw RewardRuleWriteException(RewardRuleWriteError.isHidden)
        }

        val log = RewardLog(
            ruleId = rule.id,
            date = on,
            amount = rule.amount,
            createdAt = at,
        )

        rewardLogDao().insert(log.record())
    }
}

internal suspend fun AppDatabase.currentRewardBalance(): Long {
    val logs = rewardLogDao().all().map { it.decoded(RewardLogRecord::rewardLog) }
    val goals = rewardGoalDao().all().map { it.decoded(RewardGoalRecord::rewardGoal) }

    return RewardBalance.amount(
        logs = logs,
        goals = goals,
    )
}

package com.yossibank.kakeibot.store.writes.methods

import com.yossibank.kakeibot.core.concepts.reward.RewardRule
import com.yossibank.kakeibot.core.concepts.reward.RewardRuleDraft
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.protocols.nextSortOrder
import com.yossibank.kakeibot.store.records.protocols.reorder
import com.yossibank.kakeibot.store.records.rows.IconRecord
import com.yossibank.kakeibot.store.records.rows.RewardRuleRecord
import com.yossibank.kakeibot.store.records.rows.icon
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.rows.rewardRule
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.writes.types.Deletion
import java.time.Instant

enum class RewardRuleWriteError {
    ruleNotFound,
    iconNotFound,
    hasLogs,
    shortOfBalance,
    isHidden,
}

class RewardRuleWriteException(
    val error: RewardRuleWriteError,
) : Exception(error.name)

suspend fun AppDatabase.deleteRewardRule(id: Identifier<RewardRule>): Deletion = write {
    val rule =
        findRewardRule(id) ?: throw RewardRuleWriteException(RewardRuleWriteError.ruleNotFound)

    if (rewardLogDao().countOfRule(id.databaseValue) != 0) {
        throw RewardRuleWriteException(RewardRuleWriteError.hasLogs)
    }

    val deletion = Deletion(rewardRules = listOf(rule))

    rewardRuleDao().delete(id.databaseValue)

    deletion
}

internal suspend fun AppDatabase.findRewardRule(id: Identifier<RewardRule>): RewardRule? =
    rewardRuleDao().find(id.databaseValue)?.decoded(RewardRuleRecord::rewardRule)

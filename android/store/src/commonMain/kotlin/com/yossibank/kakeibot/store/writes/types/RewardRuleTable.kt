package com.yossibank.kakeibot.store.writes.types

import com.yossibank.kakeibot.core.concepts.reward.RewardRule
import com.yossibank.kakeibot.core.concepts.reward.RewardRuleDraft
import com.yossibank.kakeibot.store.records.protocols.IconBackedTable
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.RewardRuleRecord
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.rows.rewardRule
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.writes.methods.RewardRuleWriteError
import com.yossibank.kakeibot.store.writes.methods.RewardRuleWriteException

val RewardRuleTable = IconBackedTable<RewardRule, RewardRuleDraft>(
    name = "reward_rule",
    notFoundError = { RewardRuleWriteException(RewardRuleWriteError.ruleNotFound) },
    iconNotFoundError = { RewardRuleWriteException(RewardRuleWriteError.iconNotFound) },
    iconId = { it.iconId },
    find = { rewardRuleDao().find(it.databaseValue)?.decoded(RewardRuleRecord::rewardRule) },
    insert = { rewardRuleDao().insert(it.record()) },
    update = { rewardRuleDao().update(it.record()) },
    maxSortOrder = { rewardRuleDao().maxSortOrder() },
    archived = { rule, archivedAt, at -> rule.copy(isActive = archivedAt == null, updatedAt = at) },
)

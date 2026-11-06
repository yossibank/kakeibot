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

suspend fun AppDatabase.saveRewardRule(
    draft: RewardRuleDraft,
    editing: Identifier<RewardRule>? = null,
    at: Instant,
): RewardRule = write {
    if (editing != null) {
        updateRewardRule(
            id = editing,
            with = draft,
            at = at,
        )
    } else {
        insertRewardRule(
            draft = draft,
            at = at,
        )
    }
}

suspend fun AppDatabase.reorderRewardRules(
    ids: List<Identifier<RewardRule>>,
    at: Instant,
) {
    write {
        reorder(
            table = "reward_rule",
            ids = ids.map { it.databaseValue },
            notFound = RewardRuleWriteException(RewardRuleWriteError.ruleNotFound),
            now = at,
        )
    }
}

suspend fun AppDatabase.setRewardRuleHidden(
    id: Identifier<RewardRule>,
    isHidden: Boolean,
    at: Instant,
) {
    write {
        val rule = findRewardRule(id) ?: throw RewardRuleWriteException(RewardRuleWriteError.ruleNotFound)

        val updated = rule.copy(
            isActive = !isHidden,
            updatedAt = at,
        )

        rewardRuleDao().update(updated.record())
    }
}

suspend fun AppDatabase.deleteRewardRule(id: Identifier<RewardRule>): Deletion = write {
    val rule = findRewardRule(id) ?: throw RewardRuleWriteException(RewardRuleWriteError.ruleNotFound)

    if (rewardLogDao().countOfRule(id.databaseValue) != 0) {
        throw RewardRuleWriteException(RewardRuleWriteError.hasLogs)
    }

    val deletion = Deletion(rewardRules = listOf(rule))

    rewardRuleDao().delete(id.databaseValue)

    deletion
}

internal suspend fun AppDatabase.findRewardRule(id: Identifier<RewardRule>): RewardRule? =
    rewardRuleDao().find(id.databaseValue)?.decoded(RewardRuleRecord::rewardRule)

private suspend fun AppDatabase.insertRewardRule(
    draft: RewardRuleDraft,
    at: Instant,
): RewardRule {
    val icon = draft.newIcon(at)
    val sortOrder = nextSortOrder(rewardRuleDao().maxSortOrder())

    val rule = draft.newRule(
        iconId = icon.id,
        sortOrder = sortOrder,
        at = at,
    )

    iconDao().insert(icon.record())
    rewardRuleDao().insert(rule.record())

    return rule
}

private suspend fun AppDatabase.updateRewardRule(
    id: Identifier<RewardRule>,
    with: RewardRuleDraft,
    at: Instant,
): RewardRule {
    val rule = findRewardRule(id) ?: throw RewardRuleWriteException(RewardRuleWriteError.ruleNotFound)

    val icon = iconDao().find(rule.iconId.databaseValue)?.decoded(IconRecord::icon)
        ?: throw RewardRuleWriteException(RewardRuleWriteError.iconNotFound)

    val updatedIcon = with.applied(
        to = icon,
        at = at,
    )

    iconDao().update(updatedIcon.record())

    val updated = with.applied(
        to = rule,
        at = at,
    )

    rewardRuleDao().update(updated.record())

    return updated
}

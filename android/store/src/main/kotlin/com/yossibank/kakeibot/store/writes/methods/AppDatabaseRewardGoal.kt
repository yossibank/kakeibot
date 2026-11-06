package com.yossibank.kakeibot.store.writes.methods

import com.yossibank.kakeibot.core.concepts.reward.RewardGoal
import com.yossibank.kakeibot.core.concepts.reward.RewardGoalDraft
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.RewardGoalRecord
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.rows.rewardGoal
import com.yossibank.kakeibot.store.records.values.databaseValue
import java.time.Instant

enum class RewardGoalWriteError {
    goalNotFound,
    shortOfBalance,
}

class RewardGoalWriteException(
    val error: RewardGoalWriteError,
) : Exception(error.name)

suspend fun AppDatabase.saveRewardGoal(
    draft: RewardGoalDraft,
    editing: Identifier<RewardGoal>? = null,
    at: Instant,
): RewardGoal = write {
    if (editing == null) {
        val goal = draft.newGoal(at)

        rewardGoalDao().insert(goal.record())

        return@write goal
    }

    val goal = findRewardGoal(editing) ?: throw RewardGoalWriteException(RewardGoalWriteError.goalNotFound)

    val updated = draft.applied(
        to = goal,
        at = at,
    )

    rewardGoalDao().update(updated.record())

    updated
}

suspend fun AppDatabase.setRewardGoalPurchased(
    id: Identifier<RewardGoal>,
    isPurchased: Boolean,
    at: Instant,
) {
    write {
        val goal = findRewardGoal(id) ?: throw RewardGoalWriteException(RewardGoalWriteError.goalNotFound)

        if (isPurchased && goal.purchasedAt == null && currentRewardBalance() < goal.targetAmount) {
            throw RewardGoalWriteException(RewardGoalWriteError.shortOfBalance)
        }

        val updated = goal.copy(
            purchasedAt = if (isPurchased) at else null,
            updatedAt = at,
        )

        rewardGoalDao().update(updated.record())
    }
}

suspend fun AppDatabase.deleteRewardGoal(id: Identifier<RewardGoal>) {
    write {
        if (rewardGoalDao().delete(id.databaseValue) == 0) {
            throw RewardGoalWriteException(RewardGoalWriteError.goalNotFound)
        }
    }
}

private suspend fun AppDatabase.findRewardGoal(id: Identifier<RewardGoal>): RewardGoal? =
    rewardGoalDao().find(id.databaseValue)?.decoded(RewardGoalRecord::rewardGoal)

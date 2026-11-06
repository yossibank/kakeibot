package com.yossibank.kakeibot.store.writes

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.icon.IconDraft
import com.yossibank.kakeibot.core.concepts.reward.RewardGoalDraft
import com.yossibank.kakeibot.core.concepts.reward.RewardRuleDraft
import com.yossibank.kakeibot.core.shared.DraftProblem
import com.yossibank.kakeibot.core.shared.DraftProblemException
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.rewardBank
import com.yossibank.kakeibot.store.writes.methods.RewardGoalWriteError
import com.yossibank.kakeibot.store.writes.methods.RewardGoalWriteException
import com.yossibank.kakeibot.store.writes.methods.deleteRewardGoal
import com.yossibank.kakeibot.store.writes.methods.saveRewardGoal
import com.yossibank.kakeibot.store.writes.methods.saveRewardRule
import com.yossibank.kakeibot.store.writes.methods.setReward
import com.yossibank.kakeibot.store.writes.methods.setRewardGoalPurchased
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class RewardGoalWriteTest {
    @Test
    fun savesAndEditsGoal() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(0)

        val shoes = RewardGoalDraft(
            name = " 新しい靴 ",
            targetAmount = 8000,
        )

        val renamed = RewardGoalDraft(
            name = "靴",
            targetAmount = 6000,
        )

        val goal = database.saveRewardGoal(shoes, at = now)

        val edited = database.saveRewardGoal(
            renamed,
            editing = goal.id,
            at = now,
        )

        val bank = database.rewardBank()

        assertEquals("新しい靴", goal.name)
        assertEquals(listOf(edited), bank.waitingGoals)
        assertEquals(6000, edited.targetAmount)

        database.close()
    }

    @Test
    fun rejectsGoalWithoutName() = runTest {
        val database = AppDatabase.inMemory()

        val draft = RewardGoalDraft(
            name = " ",
            targetAmount = 8000,
        )

        val error = assertFailsWith<DraftProblemException> {
            database.saveRewardGoal(draft, at = Instant.now())
        }

        assertEquals(DraftProblem.emptyName, error.problem)

        database.close()
    }

    @Test
    fun buysAndUndoesGoal() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(0)

        val draft = RewardGoalDraft(
            name = "靴",
            targetAmount = 600,
        )

        val goal = database.saveRewardGoal(draft, at = now)
        database.saveSavings(600, at = now)

        database.setRewardGoalPurchased(
            goal.id,
            isPurchased = true,
            at = now,
        )

        val bought = database.rewardBank()

        database.setRewardGoalPurchased(
            goal.id,
            isPurchased = false,
            at = now,
        )

        val undone = database.rewardBank()

        assertEquals(listOf(goal.id), bought.boughtGoals.map { it.id })
        assertEquals(0L, bought.balance)
        assertEquals(listOf(goal.id), undone.waitingGoals.map { it.id })
        assertEquals(600L, undone.balance)

        database.close()
    }

    @Test
    fun rejectsBuyingWithShortBalance() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(0)

        val draft = RewardGoalDraft(
            name = "靴",
            targetAmount = 600,
        )

        val goal = database.saveRewardGoal(draft, at = now)
        database.saveSavings(500, at = now)

        val error = assertFailsWith<RewardGoalWriteException> {
            database.setRewardGoalPurchased(
                goal.id,
                isPurchased = true,
                at = now,
            )
        }

        val bank = database.rewardBank()

        assertEquals(RewardGoalWriteError.shortOfBalance, error.error)
        assertEquals(listOf(goal.id), bank.waitingGoals.map { it.id })
        assertEquals(500L, bank.balance)

        database.close()
    }

    @Test
    fun deletesGoal() = runTest {
        val database = AppDatabase.inMemory()

        val draft = RewardGoalDraft(
            name = "靴",
            targetAmount = 600,
        )

        val goal = database.saveRewardGoal(draft, at = Instant.now())

        database.deleteRewardGoal(goal.id)
        val bank = database.rewardBank()

        assertTrue(bank.goals.isEmpty())

        database.close()
    }
}

private suspend fun AppDatabase.saveSavings(
    amount: Int,
    at: Instant,
) {
    val icon = IconDraft(
        mark = IconDraft.Mark.Glyph(Icon.Glyph.giftbox),
        color = "#E07A5F",
    )

    val draft = RewardRuleDraft(
        name = "自炊した日",
        amount = amount,
        icon = icon,
    )

    val rule = saveRewardRule(draft, at = at)
    val date = assertNotNull(LocalDate.parse("2026-10-22"))

    setReward(
        rule.id,
        isAchieved = true,
        on = date,
        at = at,
    )
}

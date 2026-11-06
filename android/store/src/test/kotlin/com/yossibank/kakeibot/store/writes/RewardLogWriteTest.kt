package com.yossibank.kakeibot.store.writes

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.icon.IconDraft
import com.yossibank.kakeibot.core.concepts.reward.RewardGoal
import com.yossibank.kakeibot.core.concepts.reward.RewardRule
import com.yossibank.kakeibot.core.concepts.reward.RewardRuleDraft
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.rewardBank
import com.yossibank.kakeibot.store.queries.methods.rewardRuleList
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.writes.methods.RewardRuleWriteError
import com.yossibank.kakeibot.store.writes.methods.RewardRuleWriteException
import com.yossibank.kakeibot.store.writes.methods.saveRewardRule
import com.yossibank.kakeibot.store.writes.methods.setReward
import com.yossibank.kakeibot.store.writes.methods.setRewardRuleHidden
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class RewardLogWriteTest {
    @Test
    fun achievesAndClearsReward() = runTest {
        val setup = Setup.make()

        setup.achieve(true)
        setup.achieve(true)
        val achieved = setup.database.rewardBank()
        setup.achieve(false)
        val cleared = setup.database.rewardBank()

        assertEquals(1, achieved.logs.size)
        assertEquals(500L, achieved.total(on = setup.date))
        assertTrue(cleared.logs.isEmpty())

        setup.database.close()
    }

    @Test
    fun countsAchievementsPerRule() = runTest {
        val setup = Setup.make()

        setup.achieve(true)
        val list = setup.database.rewardRuleList()
        val total = assertNotNull(list.total(of = setup.rule))

        assertEquals(1, total.count)
        assertEquals(500L, total.amount)

        setup.database.close()
    }

    @Test
    fun keepsAmountAtAchievement() = runTest {
        val setup = Setup.make()
        setup.achieve(true)

        val draft = RewardRuleDraft(
            name = "自炊した日",
            amount = 800,
            icon = setup.icon,
        )

        setup.database.saveRewardRule(
            draft,
            editing = setup.rule.id,
            at = setup.now,
        )

        val bank = setup.database.rewardBank()

        assertEquals(listOf(500), bank.logs.map { it.amount })

        setup.database.close()
    }

    @Test
    fun subtractsBoughtGoals() = runTest {
        val setup = Setup.make()
        setup.achieve(true)

        val bought = RewardGoal(
            name = "靴",
            targetAmount = 300,
            purchasedAt = setup.now,
            createdAt = setup.now,
            updatedAt = setup.now,
        )

        val waiting = RewardGoal(
            name = "鞄",
            targetAmount = 1000,
            createdAt = setup.now,
            updatedAt = setup.now,
        )

        setup.database.rewardGoalDao().insert(bought.record())
        setup.database.rewardGoalDao().insert(waiting.record())

        val bank = setup.database.rewardBank()

        assertEquals(200L, bank.balance)

        setup.database.close()
    }

    @Test
    fun rejectsClearingAfterPurchase() = runTest {
        val setup = Setup.make()
        setup.achieve(true)

        val bought = RewardGoal(
            name = "靴",
            targetAmount = 300,
            purchasedAt = setup.now,
            createdAt = setup.now,
            updatedAt = setup.now,
        )

        setup.database.rewardGoalDao().insert(bought.record())

        val error = assertFailsWith<RewardRuleWriteException> {
            setup.achieve(false)
        }

        val bank = setup.database.rewardBank()

        assertEquals(RewardRuleWriteError.shortOfBalance, error.error)
        assertEquals(1, bank.logs.size)
        assertEquals(200L, bank.balance)

        setup.database.close()
    }

    @Test
    fun rejectsAchievingHiddenRule() = runTest {
        val setup = Setup.make()

        setup.database.setRewardRuleHidden(
            setup.rule.id,
            isHidden = true,
            at = setup.now,
        )

        val error = assertFailsWith<RewardRuleWriteException> {
            setup.achieve(true)
        }

        val bank = setup.database.rewardBank()

        assertEquals(RewardRuleWriteError.isHidden, error.error)
        assertTrue(bank.logs.isEmpty())

        setup.database.close()
    }

    @Test
    fun clearsBeforePurchase() = runTest {
        val setup = Setup.make()
        setup.achieve(true)

        val waiting = RewardGoal(
            name = "鞄",
            targetAmount = 1000,
            createdAt = setup.now,
            updatedAt = setup.now,
        )

        setup.database.rewardGoalDao().insert(waiting.record())

        setup.achieve(false)
        val bank = setup.database.rewardBank()

        assertTrue(bank.logs.isEmpty())
        assertEquals(0L, bank.balance)

        setup.database.close()
    }

    class Setup(
        val database: AppDatabase,
        val rule: RewardRule,
        val date: LocalDate,
    ) {
        val now: Instant = Instant.ofEpochSecond(0)
        val icon = icon()

        suspend fun achieve(isAchieved: Boolean) {
            database.setReward(
                rule.id,
                isAchieved = isAchieved,
                on = date,
                at = now,
            )
        }

        companion object {
            suspend fun make(): Setup {
                val database = AppDatabase.inMemory()

                val draft = RewardRuleDraft(
                    name = "自炊した日",
                    amount = 500,
                    icon = icon(),
                )

                return Setup(
                    database = database,
                    rule = database.saveRewardRule(draft, at = Instant.ofEpochSecond(0)),
                    date = assertNotNull(LocalDate.parse("2026-10-22")),
                )
            }

            private fun icon(): IconDraft = IconDraft(
                mark = IconDraft.Mark.Glyph(Icon.Glyph.giftbox),
                color = "#E07A5F",
            )
        }
    }
}

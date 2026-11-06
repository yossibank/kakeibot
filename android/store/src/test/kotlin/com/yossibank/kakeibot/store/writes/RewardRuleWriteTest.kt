package com.yossibank.kakeibot.store.writes

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.icon.IconDraft
import com.yossibank.kakeibot.core.concepts.reward.RewardGoalDraft
import com.yossibank.kakeibot.core.concepts.reward.RewardLog
import com.yossibank.kakeibot.core.concepts.reward.RewardRule
import com.yossibank.kakeibot.core.concepts.reward.RewardRuleDraft
import com.yossibank.kakeibot.core.shared.DraftProblem
import com.yossibank.kakeibot.core.shared.DraftProblemException
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.rewardBank
import com.yossibank.kakeibot.store.queries.methods.rewardRuleList
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.RewardLogRecord
import com.yossibank.kakeibot.store.records.rows.rewardLog
import com.yossibank.kakeibot.store.writes.methods.RewardRuleWriteError
import com.yossibank.kakeibot.store.writes.methods.RewardRuleWriteException
import com.yossibank.kakeibot.store.writes.methods.deleteRewardRule
import com.yossibank.kakeibot.store.writes.methods.reorderRewardRules
import com.yossibank.kakeibot.store.writes.methods.restore
import com.yossibank.kakeibot.store.writes.methods.saveRewardGoal
import com.yossibank.kakeibot.store.writes.methods.saveRewardRule
import com.yossibank.kakeibot.store.writes.methods.setReward
import com.yossibank.kakeibot.store.writes.methods.setRewardGoalPurchased
import com.yossibank.kakeibot.store.writes.methods.setRewardRuleHidden
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class RewardRuleWriteTest {
    @Test
    fun addsRulesInOrder() = runTest {
        val setup = Setup()

        val first = setup.save("自炊した日")
        val second = setup.save("歩いて帰った日")
        val list = setup.database.rewardRuleList()
        val icon = assertNotNull(list.icons[first.iconId])

        assertEquals(listOf(first, second), list.rules)
        assertEquals(0, first.sortOrder)
        assertEquals(1, second.sortOrder)
        assertTrue(first.isActive)
        assertEquals(Icon.Glyph.giftbox, icon.glyph)

        setup.database.close()
    }

    @Test
    fun updatesRuleAndIcon() = runTest {
        val setup = Setup()
        val rule = setup.save("自炊した日")
        val later = setup.now.plusSeconds(60)

        val lunchIcon = IconDraft(
            mark = IconDraft.Mark.Text("弁"),
            color = "#9C6ADE",
        )

        val draft = RewardRuleDraft(
            name = " お弁当の日 ",
            amount = 300,
            icon = lunchIcon,
        )

        val updated = setup.database.saveRewardRule(
            draft,
            editing = rule.id,
            at = later,
        )

        val list = setup.database.rewardRuleList()
        val icon = assertNotNull(list.icons[updated.iconId])

        assertEquals(rule.id, updated.id)
        assertEquals("お弁当の日", updated.name)
        assertEquals(300, updated.amount)
        assertEquals(later, updated.updatedAt)
        assertEquals("弁", icon.text)

        setup.database.close()
    }

    @Test
    fun rejectsRuleWithoutAmount() = runTest {
        val setup = Setup()

        val draft = RewardRuleDraft(
            name = "自炊した日",
            amount = 0,
            icon = setup.icon,
        )

        val error = assertFailsWith<DraftProblemException> {
            setup.database.saveRewardRule(draft, at = setup.now)
        }

        assertEquals(DraftProblem.emptyAmount, error.problem)

        setup.database.close()
    }

    @Test
    fun reordersRules() = runTest {
        val setup = Setup()
        val first = setup.save("自炊した日")
        val second = setup.save("歩いて帰った日")

        setup.database.reorderRewardRules(
            listOf(second.id, first.id),
            at = setup.now,
        )

        val list = setup.database.rewardRuleList()

        assertEquals(listOf(second.id, first.id), list.rules.map { it.id })

        setup.database.close()
    }

    @Test
    fun hidesAndShowsRule() = runTest {
        val setup = Setup()
        val rule = setup.save("自炊した日")

        setup.database.setRewardRuleHidden(
            rule.id,
            isHidden = true,
            at = setup.now,
        )

        val hidden = setup.database.rewardRuleList()

        setup.database.setRewardRuleHidden(
            rule.id,
            isHidden = false,
            at = setup.now,
        )

        val shown = setup.database.rewardRuleList()

        assertEquals(false, hidden.rules.firstOrNull()?.isActive)
        assertEquals(true, shown.rules.firstOrNull()?.isActive)

        setup.database.close()
    }

    @Test
    fun deletesRuleWithoutLogsAndRestores() = runTest {
        val setup = Setup()
        val rule = setup.save("自炊した日")

        val deletion = setup.database.deleteRewardRule(rule.id)
        val deleted = setup.database.rewardRuleList()
        setup.database.restore(deletion)
        val restored = setup.database.rewardRuleList()

        assertTrue(deleted.rules.isEmpty())
        assertEquals(listOf(rule), restored.rules)

        setup.database.close()
    }

    @Test
    fun keepsRuleWithLogs() = runTest {
        val setup = Setup()
        val rule = setup.save("自炊した日")
        val date = assertNotNull(LocalDate.parse("2026-10-22"))

        setup.database.setReward(
            rule.id,
            isAchieved = true,
            on = date,
            at = setup.now,
        )

        val error = assertFailsWith<RewardRuleWriteException> {
            setup.database.deleteRewardRule(rule.id)
        }

        val list = setup.database.rewardRuleList()
        val logs = setup.logs()

        assertEquals(RewardRuleWriteError.hasLogs, error.error)
        assertEquals(listOf(rule), list.rules)
        assertEquals(1, logs.size)

        setup.database.close()
    }

    @Test
    fun keepsBalanceNonNegativeWhenRuleIsDeleted() = runTest {
        val setup = Setup()
        val rule = setup.save("自炊した日")
        val first = assertNotNull(LocalDate.parse("2026-10-01"))

        val shoes = RewardGoalDraft(
            name = "靴",
            targetAmount = 30000,
        )

        for (offset in 0 until 60) {
            setup.database.setReward(
                rule.id,
                isAchieved = true,
                on = first.adding(days = offset),
                at = setup.now,
            )
        }

        val goal = setup.database.saveRewardGoal(shoes, at = setup.now)

        setup.database.setRewardGoalPurchased(
            goal.id,
            isPurchased = true,
            at = setup.now,
        )

        runCatching { setup.database.deleteRewardRule(rule.id) }
        val bank = setup.database.rewardBank()

        assertEquals(0L, bank.balance)

        setup.database.close()
    }

    class Setup {
        val database: AppDatabase = AppDatabase.inMemory()
        val now: Instant = Instant.ofEpochSecond(0)

        val icon = IconDraft(
            mark = IconDraft.Mark.Glyph(Icon.Glyph.giftbox),
            color = "#E07A5F",
        )

        suspend fun save(name: String): RewardRule {
            val draft = RewardRuleDraft(
                name = name,
                amount = 500,
                icon = icon,
            )

            return database.saveRewardRule(draft, at = now)
        }

        suspend fun logs(): List<RewardLog> = database.rewardLogDao().all().map { it.decoded(RewardLogRecord::rewardLog) }
    }
}

package com.yossibank.kakeibot.store.queries

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.icon.IconDraft
import com.yossibank.kakeibot.core.concepts.reward.RewardRuleDraft
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.rewardBank
import com.yossibank.kakeibot.store.writes.methods.saveRewardRule
import com.yossibank.kakeibot.store.writes.methods.setReward
import com.yossibank.kakeibot.store.writes.methods.setRewardRuleHidden
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

class RewardBankTest {
    @Test
    fun listsHiddenRulesOnlyOnDaysTheyWereAchieved() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(0)
        val day = assertNotNull(LocalDate.parse("2026-10-22"))
        val other = assertNotNull(LocalDate.parse("2026-10-23"))

        val icon = IconDraft(
            mark = IconDraft.Mark.Glyph(Icon.Glyph.giftbox),
            color = "#E07A5F",
        )

        val shown = database.saveRewardRule(
            RewardRuleDraft(
                name = "自炊した日",
                amount = 500,
                icon = icon,
            ),
            at = now,
        )

        val hidden = database.saveRewardRule(
            RewardRuleDraft(
                name = "歩いて帰った日",
                amount = 300,
                icon = icon,
            ),
            at = now,
        )

        database.setReward(
            hidden.id,
            isAchieved = true,
            on = day,
            at = now,
        )

        database.setRewardRuleHidden(
            hidden.id,
            isHidden = true,
            at = now,
        )

        val bank = database.rewardBank()

        assertEquals(
            listOf(
                shown.id,
                hidden.id,
            ),
            bank.rules(on = day).map { it.id },
        )
        assertEquals(listOf(shown.id), bank.rules(on = other).map { it.id })

        database.close()
    }
}

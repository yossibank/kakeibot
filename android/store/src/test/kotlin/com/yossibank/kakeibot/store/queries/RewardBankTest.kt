package com.yossibank.kakeibot.store.queries

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.rewardBank
import com.yossibank.kakeibot.store.support.hideRewardRule
import com.yossibank.kakeibot.store.support.insertRewardLog
import com.yossibank.kakeibot.store.support.insertRewardRule
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

        val shown = database.insertRewardRule(
            name = "自炊した日",
            amount = 500,
            glyph = Icon.Glyph.giftbox,
            color = "#E07A5F",
            at = now,
        )

        val hidden = database.insertRewardRule(
            name = "歩いて帰った日",
            amount = 300,
            glyph = Icon.Glyph.giftbox,
            color = "#E07A5F",
            at = now,
        )

        database.insertRewardLog(
            rule = hidden,
            date = day,
            at = now,
        )

        database.hideRewardRule(
            id = hidden.id,
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

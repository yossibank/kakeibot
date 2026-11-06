package com.yossibank.kakeibot.store.writes

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryDraft
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.icon.IconDraft
import com.yossibank.kakeibot.core.concepts.reward.RewardGoalDraft
import com.yossibank.kakeibot.core.concepts.reward.RewardRuleDraft
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.insertDefaultsIfEmpty
import com.yossibank.kakeibot.store.support.execute
import com.yossibank.kakeibot.store.support.rows
import com.yossibank.kakeibot.store.writes.methods.deletableRecordCount
import com.yossibank.kakeibot.store.writes.methods.deleteAllRecords
import com.yossibank.kakeibot.store.writes.methods.markNoSpendDay
import com.yossibank.kakeibot.store.writes.methods.saveEntry
import com.yossibank.kakeibot.store.writes.methods.saveRewardGoal
import com.yossibank.kakeibot.store.writes.methods.saveRewardRule
import com.yossibank.kakeibot.store.writes.methods.saveValuation
import com.yossibank.kakeibot.store.writes.methods.setReward
import com.yossibank.kakeibot.store.writes.methods.stamp
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

class RecordResetWriteTest {
    @Test
    fun deletesOwnRecords() = runTest {
        val setup = Setup.make()
        setup.addOwnRecords()

        setup.database.deleteAllRecords(at = setup.now)

        assertEquals(0, setup.count("entry"))
        assertEquals(0, setup.count("valuation"))
        assertEquals(0, setup.count("reward_log"))
        assertEquals(0, setup.count("calendar_stamp"))
        assertEquals(0, setup.count("no_spend_day"))

        setup.database.close()
    }

    @Test
    fun keepsSettingsAndPlans() = runTest {
        val setup = Setup.make()
        val tables = listOf("wallet", "category", "tag", "budget", "template", "recurring", "setting")
        setup.addOwnRecords()
        val before = setup.counts(tables)

        setup.database.deleteAllRecords(at = setup.now)
        val after = setup.counts(tables)

        assertEquals(before, after)
        assertEquals(1, setup.count("reward_rule"))

        setup.database.close()
    }

    @Test
    fun detachesRewardGoals() = runTest {
        val setup = Setup.make()
        val entry = setup.addOwnRecords()

        val draft = RewardGoalDraft(
            name = "靴",
            targetAmount = 600,
        )

        val goal = setup.database.saveRewardGoal(draft, at = setup.now)
        setup.database.execute("UPDATE reward_goal SET entry_id = '${entry.id}'")

        setup.database.deleteAllRecords(at = setup.now)

        assertEquals(1, setup.count("reward_goal WHERE id = '${goal.id}' AND entry_id IS NULL"))

        setup.database.close()
    }

    @Test
    fun countsRecordsWithoutEntries() = runTest {
        val setup = Setup.make()
        val day = assertNotNull(LocalDate.parse("2026-10-13"))

        setup.database.markNoSpendDay(
            day,
            at = setup.now,
        )

        val count = setup.database.deletableRecordCount()

        assertEquals(1, count)

        setup.database.close()
    }

    class Setup(
        val database: AppDatabase,
        val other: Identifier<Wallet>,
        val food: Identifier<EntryCategory>,
    ) {
        val now: Instant = Instant.ofEpochSecond(1_791_000_000)

        suspend fun count(source: String): Int {
            val row = database.rows("SELECT COUNT(*) AS count FROM $source").first()

            return (row["count"] as Long).toInt()
        }

        suspend fun counts(tables: List<String>): List<Int> = tables.map { count(it) }

        suspend fun addOwnRecords(): Entry {
            val day = assertNotNull(LocalDate.parse("2026-10-12"))
            val noSpend = assertNotNull(LocalDate.parse("2026-10-13"))
            val icon = assertNotNull(value("SELECT id FROM icon ORDER BY id"))

            val ruleDraft = RewardRuleDraft(
                name = "自炊した日",
                amount = 500,
                icon = IconDraft(
                    mark = IconDraft.Mark.Glyph(Icon.Glyph.giftbox),
                    color = "#E07A5F",
                ),
            )

            val rule = database.saveRewardRule(ruleDraft, at = now)

            val draft = EntryDraft(
                type = Entry.Kind.expense,
                amount = 500,
                date = day,
                categoryId = food,
                walletId = other,
            )

            val entry = database.saveEntry(draft, at = now)

            database.saveValuation(
                150_000,
                of = other,
                on = day,
                at = now,
            )

            database.setReward(
                rule.id,
                isAchieved = true,
                on = day,
                at = now,
            )

            database.stamp(
                assertNotNull(Identifier.parse<Icon>(icon)),
                on = day,
                at = now,
            )

            database.markNoSpendDay(
                noSpend,
                at = now,
            )

            return entry
        }

        private suspend fun value(sql: String): String? = database.rows(sql).firstOrNull()?.values?.firstOrNull() as String?

        companion object {
            suspend fun make(): Setup {
                val database = AppDatabase.inMemory()

                database.insertDefaultsIfEmpty(Instant.ofEpochSecond(1_791_000_000))

                val other = database.rows("SELECT id FROM wallet ORDER BY sort_order LIMIT 1 OFFSET 1").first()["id"] as String
                val food = database.rows("SELECT id FROM category WHERE name = '食費'").first()["id"] as String

                return Setup(
                    database = database,
                    other = assertNotNull(Identifier.parse(other)),
                    food = assertNotNull(Identifier.parse(food)),
                )
            }
        }
    }
}

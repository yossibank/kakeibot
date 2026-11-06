package com.yossibank.kakeibot.store.writes

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryBatchChange
import com.yossibank.kakeibot.core.concepts.entry.EntryDraft
import com.yossibank.kakeibot.core.concepts.entry.NoSpendDay
import com.yossibank.kakeibot.core.concepts.reward.RewardGoalDraft
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.insertDefaultsIfEmpty
import com.yossibank.kakeibot.store.queries.methods.entry
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.snapshot.snapshot
import com.yossibank.kakeibot.store.support.execute
import com.yossibank.kakeibot.store.writes.methods.WriteError
import com.yossibank.kakeibot.store.writes.methods.WriteException
import com.yossibank.kakeibot.store.writes.methods.changeEntries
import com.yossibank.kakeibot.store.writes.methods.deleteEntries
import com.yossibank.kakeibot.store.writes.methods.deleteEntry
import com.yossibank.kakeibot.store.writes.methods.markNoSpendDay
import com.yossibank.kakeibot.store.writes.methods.restoreEntries
import com.yossibank.kakeibot.store.writes.methods.restoreEntry
import com.yossibank.kakeibot.store.writes.methods.saveEntries
import com.yossibank.kakeibot.store.writes.methods.saveEntry
import com.yossibank.kakeibot.store.writes.methods.saveEntryResult
import com.yossibank.kakeibot.store.writes.methods.saveRewardGoal
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class EntryWriteTest {
    @Test
    fun reportsAndRestoresClearedNoSpendDay() = runTest {
        val setup = Setup.make()

        setup.database.markNoSpendDay(
            setup.draft.date,
            at = setup.now,
        )

        val result = setup.database.saveEntryResult(setup.draft, at = setup.now)
        val cleared = setup.database.snapshot().noSpendDays

        setup.database.deleteEntry(
            result.entry.id,
            restoringNoSpend = result.clearedNoSpendDays,
        )

        val restored = setup.database.snapshot().noSpendDays

        assertEquals(listOf(setup.draft.date), result.clearedNoSpendDays.map { it.date })
        assertTrue(cleared.isEmpty())
        assertEquals(listOf(setup.draft.date), restored.map { it.date })

        setup.database.close()
    }

    @Test
    fun doesNotMakeNoSpendDayOnUnmarkedDay() = runTest {
        val setup = Setup.make()

        val result = setup.database.saveEntryResult(setup.draft, at = setup.now)

        setup.database.deleteEntry(
            result.entry.id,
            restoringNoSpend = result.clearedNoSpendDays,
        )

        val snapshot = setup.database.snapshot()

        assertTrue(result.clearedNoSpendDays.isEmpty())
        assertTrue(snapshot.noSpendDays.isEmpty())

        setup.database.close()
    }

    @Test
    fun savesNewEntry() = runTest {
        val setup = Setup.make()

        val saved = setup.database.saveEntry(setup.draft, at = setup.now)
        val snapshot = setup.database.snapshot()

        assertEquals(listOf(saved), snapshot.entries)

        setup.database.close()
    }

    @Test
    fun updatesExistingEntry() = runTest {
        val setup = Setup.make()
        val later = setup.now.plusSeconds(60)
        val edited = setup.draft.copy(amount = 1500)

        val saved = setup.database.saveEntry(setup.draft, at = setup.now)

        val updated = setup.database.saveEntry(
            edited,
            editing = saved.id,
            at = later,
        )

        val snapshot = setup.database.snapshot()

        assertEquals(listOf(updated), snapshot.entries)
        assertEquals(1500, updated.amount)
        assertEquals(setup.now, updated.createdAt)
        assertEquals(later, updated.updatedAt)

        setup.database.close()
    }

    @Test
    fun rejectsUnknownEntry() = runTest {
        val setup = Setup.make()

        val error = assertFailsWith<WriteException> {
            setup.database.saveEntry(
                setup.draft,
                editing = Identifier(),
                at = setup.now,
            )
        }

        assertEquals(WriteError.entryNotFound, error.error)

        setup.database.close()
    }

    @Test
    fun rejectsInvalidDraft() = runTest {
        val setup = Setup.make()
        val draft = setup.draft.copy(amount = 0)

        val error = assertFailsWith<EntryDraft.ProblemException> {
            setup.database.saveEntry(draft, at = setup.now)
        }

        assertEquals(EntryDraft.Problem.amountNotPositive, error.problem)

        setup.database.close()
    }

    @Test
    fun clearsNoSpendDayOnlyForExpense() = runTest {
        for (type in listOf(Entry.Kind.expense, Entry.Kind.income)) {
            val setup = Setup.make()
            val options = setup.database.entryOptions()
            val categories = if (type == Entry.Kind.expense) options.expenseCategories else options.incomeCategories

            val draft = setup.draft.copy(
                type = type,
                categoryId = categories[0].id,
            )

            val noSpendDay = NoSpendDay(
                date = draft.date,
                createdAt = setup.now,
            )

            setup.database.noSpendDayDao().insert(noSpendDay.record())

            setup.database.saveEntry(draft, at = setup.now)
            val snapshot = setup.database.snapshot()

            assertEquals(type == Entry.Kind.expense, snapshot.noSpendDays.isEmpty())

            setup.database.close()
        }
    }

    @Test
    fun savesEntriesTogetherOrNotAtAll() = runTest {
        val setup = Setup.make()
        val invalid = setup.draft.copy(amount = 0)

        setup.database.saveEntries(
            listOf(setup.draft, setup.draft),
            at = setup.now,
        )

        val saved = setup.database.snapshot().entries.size

        assertFailsWith<Exception> {
            setup.database.saveEntries(
                listOf(setup.draft, invalid),
                at = setup.now,
            )
        }

        val after = setup.database.snapshot().entries.size

        assertEquals(2, saved)
        assertEquals(2, after)

        setup.database.close()
    }

    @Test
    fun deletesEntry() = runTest {
        val setup = Setup.make()

        val saved = setup.database.saveEntry(setup.draft, at = setup.now)

        setup.database.deleteEntry(saved.id)
        val snapshot = setup.database.snapshot()

        assertTrue(snapshot.entries.isEmpty())

        setup.database.close()
    }

    @Test
    fun deletesEntryPointedByRewardGoal() = runTest {
        val setup = Setup.make()

        val goalDraft = RewardGoalDraft(
            name = "靴",
            targetAmount = 6000,
        )

        val saved = setup.database.saveEntry(setup.draft, at = setup.now)
        val goal = setup.database.saveRewardGoal(goalDraft, at = setup.now)

        setup.database.execute(
            "UPDATE reward_goal SET entry_id = ? WHERE id = ?",
            saved.id.databaseValue,
            goal.id.databaseValue,
        )

        setup.database.deleteEntry(saved.id)
        val snapshot = setup.database.snapshot()

        assertTrue(snapshot.entries.isEmpty())
        assertEquals(listOf(null), snapshot.rewardGoals.map { it.entryId })

        setup.database.close()
    }

    @Test
    fun restoresDeletedAndEditedEntry() = runTest {
        val setup = Setup.make()
        val later = setup.now.plusSeconds(60)
        val edited = setup.draft.copy(amount = 1500)

        val saved = setup.database.saveEntry(setup.draft, at = setup.now)

        setup.database.deleteEntry(saved.id)
        setup.database.restoreEntry(saved)
        val restored = setup.database.snapshot().entries

        setup.database.saveEntry(
            edited,
            editing = saved.id,
            at = later,
        )

        setup.database.restoreEntry(saved)
        val reverted = setup.database.snapshot().entries

        assertEquals(listOf(saved), restored)
        assertEquals(listOf(saved), reverted)

        setup.database.close()
    }

    @Test
    fun changesCategoryOnlyForMatchingType() = runTest {
        val setup = Setup.make()
        val options = setup.database.entryOptions()
        val category = options.expenseCategories[1]
        val later = setup.now.plusSeconds(60)

        val income = setup.draft.copy(
            type = Entry.Kind.income,
            categoryId = options.incomeCategories[0].id,
        )

        val spent = setup.database.saveEntry(setup.draft, at = setup.now)
        val earned = setup.database.saveEntry(income, at = setup.now)

        val previous = setup.database.changeEntries(
            listOf(spent.id, earned.id),
            to = EntryBatchChange.Category(category.id),
            at = later,
        )

        val changed = setup.database.entry(spent.id)
        val kept = setup.database.entry(earned.id)

        assertEquals(listOf(spent), previous)
        assertEquals(category.id, changed?.categoryId)
        assertEquals(later, changed?.updatedAt)
        assertEquals(earned, kept)

        setup.database.close()
    }

    @Test
    fun changesWalletOfEntries() = runTest {
        val setup = Setup.make()
        val options = setup.database.entryOptions()
        val wallet = options.wallets[1]

        val saved = setup.database.saveEntry(setup.draft, at = setup.now)

        val previous = setup.database.changeEntries(
            listOf(saved.id),
            to = EntryBatchChange.Wallet(wallet.id),
            at = setup.now,
        )

        val changed = setup.database.entry(saved.id)

        assertEquals(listOf(saved), previous)
        assertEquals(wallet.id, changed?.walletId)

        setup.database.close()
    }

    @Test
    fun deletesAndRestoresEntries() = runTest {
        val setup = Setup.make()

        val first = setup.database.saveEntry(setup.draft, at = setup.now)
        val second = setup.database.saveEntry(setup.draft, at = setup.now)

        val deleted = setup.database.deleteEntries(listOf(first.id, second.id))
        val emptied = setup.database.snapshot().entries
        setup.database.restoreEntries(deleted)
        val restored = setup.database.snapshot().entries

        assertEquals(setOf(first, second), deleted.toSet())
        assertTrue(emptied.isEmpty())
        assertEquals(setOf(first, second), restored.toSet())

        setup.database.close()
    }

    class Setup(
        val database: AppDatabase,
        val now: Instant,
        val draft: EntryDraft,
    ) {
        companion object {
            suspend fun make(): Setup {
                val database = AppDatabase.inMemory()
                val now = Instant.ofEpochSecond(1_791_000_000)
                val date = assertNotNull(LocalDate.parse("2026-10-03"))

                database.insertDefaultsIfEmpty(now)

                val options = database.entryOptions()

                val draft = EntryDraft(
                    type = Entry.Kind.expense,
                    amount = 980,
                    date = date,
                    categoryId = options.expenseCategories[0].id,
                    walletId = options.wallets[0].id,
                    memo = "ランチ",
                )

                return Setup(
                    database = database,
                    now = now,
                    draft = draft,
                )
            }
        }
    }
}

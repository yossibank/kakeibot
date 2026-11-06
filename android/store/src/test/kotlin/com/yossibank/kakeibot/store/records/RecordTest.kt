package com.yossibank.kakeibot.store.records

import androidx.sqlite.SQLiteException
import com.yossibank.kakeibot.core.concepts.budget.Budget
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.reward.RewardLog
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.records.rows.entry
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.support.execute
import com.yossibank.kakeibot.store.support.rows
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class RecordTest {
    @Test
    fun roundTripsEveryTable() = runTest {
        val database = AppDatabase.inMemory()
        val sample = RecordTestSample()

        sample.insert(database)

        val stored = RecordTestTables.fetchingFrom(database)

        assertEquals(sample.tables, stored)

        database.close()
    }

    @Test
    fun storesValuesAsText() = runTest {
        val database = AppDatabase.inMemory()
        val sample = RecordTestSample()

        sample.insert(database)

        val row = database.rows(EXPENSE_QUERY).single()

        assertEquals(sample.expense.id.toString(), row["id"])
        assertEquals("expense", row["type"])
        assertEquals("2026-02-27", row["date"])
        assertEquals("2026-10-03T04:00:00Z", row["created_at"])

        database.close()
    }

    @Test
    fun readsStoredTimes() = runTest {
        val cases = listOf(
            "2026-10-29T02:32:29Z" to Instant.ofEpochSecond(1_793_241_149),
            "2026-10-29T11:32:29+09:00" to Instant.ofEpochSecond(1_793_241_149),
            "2026-10-29T02:32:29.250Z" to Instant.ofEpochSecond(1_793_241_149, 250_000_000),
        )

        for ((text, instant) in cases) {
            val database = AppDatabase.inMemory()
            val sample = RecordTestSample()

            sample.insert(database)
            database.execute(EXPENSE_TIME_UPDATE, text)

            val entry = database.entryDao().find(sample.expense.id.toString())?.entry()

            assertEquals(instant, entry?.createdAt, text)

            database.close()
        }
    }

    @Test
    fun acceptsValidEntry() = runTest {
        val database = AppDatabase.inMemory()
        val sample = RecordTestSample()

        val entry = sample.entry(
            type = Entry.Kind.expense,
            categoryId = sample.category.id,
            toWalletId = null,
        )

        sample.insert(database)

        database.write {
            database.entryDao().insert(entry.record())
        }

        assertEquals(3, database.entryDao().count())

        database.close()
    }

    @Test
    fun rejectsInvalidRow() = runTest {
        for (invalid in InvalidRow.entries) {
            val database = AppDatabase.inMemory()
            val sample = RecordTestSample()

            sample.insert(database)

            assertFailsWith<SQLiteException>(invalid.name) {
                database.write {
                    invalid.insert(
                        alongside = sample,
                        into = database,
                    )
                }
            }

            database.close()
        }
    }

    enum class InvalidRow {
        expenseWithoutCategory,
        transferWithCategory,
        transferToSameWallet,
        zeroAmount,
        duplicateRecurringDate,
        unknownWallet,
        secondWholeMonthBudget,
        duplicateRewardLog,
        iconWithoutEmojiOrText,
        ;

        suspend fun insert(
            alongside: RecordTestSample,
            into: AppDatabase,
        ) {
            val sample = alongside

            when (this) {
                expenseWithoutCategory -> into.insert(
                    sample.entry(
                        type = Entry.Kind.expense,
                        categoryId = null,
                        toWalletId = null,
                    ),
                )

                transferWithCategory -> into.insert(
                    sample.entry(
                        type = Entry.Kind.transfer,
                        categoryId = sample.category.id,
                        toWalletId = sample.cash.id,
                    ),
                )

                transferToSameWallet -> into.insert(
                    sample.entry(
                        type = Entry.Kind.transfer,
                        categoryId = null,
                        toWalletId = sample.bank.id,
                    ),
                )

                zeroAmount -> into.insert(
                    sample.entry(
                        type = Entry.Kind.expense,
                        categoryId = sample.category.id,
                        toWalletId = null,
                        amount = 0,
                    ),
                )

                duplicateRecurringDate -> into.insert(
                    sample.entry(
                        type = Entry.Kind.expense,
                        categoryId = sample.category.id,
                        toWalletId = null,
                        recurringId = sample.recurring.id,
                        recurringDate = sample.expense.recurringDate,
                    ),
                )

                unknownWallet -> into.insert(
                    sample.entry(
                        type = Entry.Kind.expense,
                        categoryId = sample.category.id,
                        toWalletId = null,
                        walletId = Identifier(),
                    ),
                )

                secondWholeMonthBudget -> into.budgetDao().insert(
                    Budget(
                        categoryId = null,
                        fromMonth = sample.wholeBudget.fromMonth,
                        amount = 1,
                    ).record(),
                )

                duplicateRewardLog -> into.rewardLogDao().insert(
                    RewardLog(
                        ruleId = sample.rule.id,
                        date = sample.rewardLog.date,
                        amount = 1,
                        createdAt = sample.now,
                    ).record(),
                )

                iconWithoutEmojiOrText -> into.iconDao().insert(
                    Icon(
                        emoji = null,
                        text = null,
                        color = "#000000",
                        createdAt = sample.now,
                        updatedAt = sample.now,
                    ).record(),
                )
            }
        }

        private suspend fun AppDatabase.insert(entry: Entry) {
            entryDao().insert(entry.record())
        }
    }

    private companion object {
        const val EXPENSE_QUERY = "SELECT * FROM entry WHERE type = 'expense'"
        const val EXPENSE_TIME_UPDATE = "UPDATE entry SET created_at = ? WHERE type = 'expense'"
    }
}

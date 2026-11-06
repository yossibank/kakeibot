package com.yossibank.kakeibot.store.writes.methods

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.NoSpendDay
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.values.databaseValue
import java.time.Instant

enum class NoSpendDayError {
    hasExpense,
}

class NoSpendDayException(
    val error: NoSpendDayError,
) : Exception(error.name)

suspend fun AppDatabase.markNoSpendDay(
    date: LocalDate,
    at: Instant,
) {
    markNoSpendDays(
        dates = listOf(date),
        at = at,
    )
}

suspend fun AppDatabase.markNoSpendDays(
    dates: List<LocalDate>,
    at: Instant,
) {
    write {
        for (date in dates) {
            if (entryDao().countExpenses(date.databaseValue) != 0) {
                throw NoSpendDayException(NoSpendDayError.hasExpense)
            }

            val day = NoSpendDay(
                date = date,
                createdAt = at,
            )

            noSpendDayDao().save(day.record())
        }
    }
}

suspend fun AppDatabase.unmarkNoSpendDay(date: LocalDate) {
    write {
        noSpendDayDao().delete(date.databaseValue)
    }
}

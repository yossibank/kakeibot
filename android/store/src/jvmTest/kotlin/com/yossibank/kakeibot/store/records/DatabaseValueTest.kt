package com.yossibank.kakeibot.store.records

import androidx.sqlite.SQLiteConnection
import androidx.sqlite.driver.bundled.BundledSQLiteDriver
import androidx.sqlite.execSQL
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.records.values.fromDatabaseValue
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class DatabaseValueTest {
    @Test
    fun storesLocalDateAsText() {
        val database = makeDatabase()
        val date = checkNotNull(LocalDate.parse("2026-02-01"))

        database.insert(date.databaseValue)
        val text = database.fetch()
        val decoded = LocalDate.fromDatabaseValue(text)

        assertEquals("2026-02-01", text)
        assertEquals(date, decoded)

        database.close()
    }

    @Test
    fun storesYearMonthAsText() {
        val database = makeDatabase()
        val month = checkNotNull(YearMonth.parse("2026-02"))

        database.insert(month.databaseValue)
        val text = database.fetch()
        val decoded = YearMonth.fromDatabaseValue(text)

        assertEquals("2026-02", text)
        assertEquals(month, decoded)

        database.close()
    }

    @Test
    fun rejectsInvalidText() {
        val database = makeDatabase()

        database.insert("2026-02-30")

        assertNull(LocalDate.fromDatabaseValue(database.fetch()))

        database.close()
    }

    private fun makeDatabase(): SQLiteConnection {
        val connection = BundledSQLiteDriver().open(":memory:")

        connection.execSQL("CREATE TABLE sample (value TEXT)")

        return connection
    }

    private fun SQLiteConnection.insert(value: String) {
        prepare("INSERT INTO sample (value) VALUES (?)").use { statement ->
            statement.bindText(1, value)
            statement.step()
        }
    }

    private fun SQLiteConnection.fetch(): String = prepare("SELECT value FROM sample").use { statement ->
        statement.step()
        statement.getText(0)
    }
}

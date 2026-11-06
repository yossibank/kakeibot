package com.yossibank.kakeibot.store.database

import androidx.sqlite.SQLiteException
import com.yossibank.kakeibot.store.support.execute
import com.yossibank.kakeibot.store.support.rows
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.io.File
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class AppDatabaseTest {
    @Test
    fun createsEveryTable() = runTest {
        val database = AppDatabase.inMemory()

        val tables = database.rows(TABLE_QUERY).map { it["name"] }.toSet()

        assertEquals(TABLES, tables)

        database.close()
    }

    @Test
    fun opensFileWithDefaultsAndChecks() = runTest {
        val directory = File.createTempFile("kakeibot", "").apply {
            delete()
            mkdirs()
        }

        val path = File(directory, "kakeibot.sqlite").path
        val now = Instant.ofEpochSecond(1_791_000_000)

        AppDatabase.file(path, now).close()
        val database = AppDatabase.file(path, now)

        assertEquals(2, database.walletDao().count())
        assertEquals(8, database.shelfIconDao().count())

        assertFailsWith<SQLiteException> {
            database.execute("UPDATE wallet SET kind = 'unknown'")
        }

        database.close()
        directory.deleteRecursively()
    }

    private companion object {
        const val TABLE_QUERY = """
            SELECT name FROM sqlite_master
            WHERE type = 'table' AND name NOT LIKE 'sqlite_%' AND name <> 'room_master_table'
        """

        val TABLES = setOf(
            "adjustment",
            "budget",
            "calendar_stamp",
            "category",
            "entry",
            "entry_item",
            "icon",
            "item_name",
            "no_spend_day",
            "recurring",
            "reward_goal",
            "reward_log",
            "reward_rule",
            "setting",
            "shelf_icon",
            "tag",
            "template",
            "theme",
            "valuation",
            "wallet",
        )
    }
}

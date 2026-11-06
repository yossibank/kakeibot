package com.yossibank.kakeibot.store.migrations

import androidx.sqlite.SQLiteException
import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.support.execute
import com.yossibank.kakeibot.store.support.rows
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.boolean
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class LatestSchemaTest {
    @Test
    fun walletAcceptsEveryKind() = runTest {
        val database = makeDatabase()

        for ((index, kind) in Wallet.Kind.entries.withIndex()) {
            val accepted = database.accepts(
                INSERT_WALLET,
                id(index + 10),
                kind.rawValue,
            )

            assertTrue(accepted, HINT)
        }

        val unknown = database.accepts(
            INSERT_WALLET,
            id(99),
            "unknown",
        )

        assertFalse(unknown)

        database.close()
    }

    @Test
    fun categoryAcceptsEveryKind() = runTest {
        val database = makeDatabase()

        for ((index, kind) in EntryCategory.Kind.entries.withIndex()) {
            val accepted = database.accepts(
                INSERT_CATEGORY,
                id(index + 10),
                kind.rawValue,
            )

            assertTrue(accepted, HINT)
        }

        val unknown = database.accepts(
            INSERT_CATEGORY,
            id(99),
            "unknown",
        )

        assertFalse(unknown)

        database.close()
    }

    @Test
    fun recurringAcceptsEveryFrequency() = runTest {
        val database = makeDatabase()

        for ((index, frequency) in Recurring.Frequency.entries.withIndex()) {
            val month = if (frequency == Recurring.Frequency.yearly) 1 else null

            val accepted = database.accepts(
                INSERT_RECURRING,
                id(index + 10),
                frequency.rawValue,
                month,
            )

            assertTrue(accepted, HINT)
        }

        val unknown = database.accepts(
            INSERT_RECURRING,
            id(99),
            "unknown",
            null,
        )

        assertFalse(unknown)

        database.close()
    }

    @Test
    fun entryAcceptsEveryKind() = runTest {
        val database = makeDatabase()

        for ((index, kind) in Entry.Kind.entries.withIndex()) {
            val isTransfer = kind == Entry.Kind.transfer

            val accepted = database.accepts(
                INSERT_ENTRY,
                id(index + 10),
                kind.rawValue,
                if (isTransfer) null else CATEGORY_ID,
                if (isTransfer) TO_WALLET_ID else null,
            )

            assertTrue(accepted, HINT)
        }

        val unknown = database.accepts(
            INSERT_ENTRY,
            id(99),
            "unknown",
            CATEGORY_ID,
            null,
        )

        assertFalse(unknown)

        database.close()
    }

    @Test
    fun matchesIosSchema() = runTest {
        val database = AppDatabase.inMemory()
        val expected = iosSchema()

        val names = database.rows(TABLE_QUERY).map { it["name"] as String }
        val actual = names.map { database.table(it) }

        assertEquals(expected.map { it.name }.sorted(), names.sorted())

        for (table in actual) {
            assertEquals(expected.single { it.name == table.name }, table, table.name)
        }

        val triggers = database.rows(TRIGGER_QUERY).map { it["name"] as String }

        assertTrue("budget_whole_month_insert" in triggers)
        assertTrue("budget_whole_month_update" in triggers)
        assertEquals(1L, database.rows("PRAGMA foreign_keys").single()["foreign_keys"])

        database.close()
    }

    private data class Table(
        val name: String,
        val columns: List<Column>,
        val foreignKeys: Set<ForeignKey>,
        val indexes: Set<Index>,
    )

    private data class Column(
        val name: String,
        val type: String,
        val notNull: Boolean,
        val primaryKey: Boolean,
        val default: String?,
    )

    private data class ForeignKey(
        val column: String,
        val table: String,
        val to: String,
        val onDelete: String,
    )

    private data class Index(
        val columns: List<String>,
        val unique: Boolean,
    )

    private suspend fun makeDatabase(): AppDatabase {
        val database = AppDatabase.inMemory()

        database.execute(INSERT_ICON, ICON_ID)
        database.execute(INSERT_WALLET, WALLET_ID, "cash")
        database.execute(INSERT_WALLET, TO_WALLET_ID, "bank")
        database.execute(INSERT_CATEGORY, CATEGORY_ID, "expense")

        return database
    }

    private suspend fun AppDatabase.accepts(
        sql: String,
        vararg arguments: Any?,
    ): Boolean = try {
        execute(sql, *arguments)
        true
    } catch (error: SQLiteException) {
        if (error.message?.contains("CHECK constraint failed") != true) {
            throw error
        }

        false
    }

    private suspend fun AppDatabase.table(name: String): Table {
        val columns = rows("PRAGMA table_info(`$name`)").map { row ->
            Column(
                name = row["name"] as String,
                type = row["type"] as String,
                notNull = row["notnull"] == 1L,
                primaryKey = row["pk"] != 0L,
                default = row["dflt_value"] as String?,
            )
        }

        val foreignKeys = rows("PRAGMA foreign_key_list(`$name`)").map { row ->
            ForeignKey(
                column = row["from"] as String,
                table = row["table"] as String,
                to = row["to"] as String,
                onDelete = row["on_delete"] as String,
            )
        }

        val indexes = rows("PRAGMA index_list(`$name`)")
            .filter { it["origin"] != "pk" }
            .map { row ->
                val indexName = row["name"] as String
                val indexColumns = rows("PRAGMA index_info(`$indexName`)").map { it["name"] as String }

                Index(
                    columns = indexColumns,
                    unique = row["unique"] == 1L,
                )
            }

        return Table(
            name = name,
            columns = columns,
            foreignKeys = foreignKeys.toSet(),
            indexes = indexes.toSet(),
        )
    }

    private fun iosSchema(): List<Table> {
        val text = javaClass.getResource("/ios-schema.json")?.readText() ?: error("ios-schema.json が無い")
        val tables = Json.parseToJsonElement(text).jsonObject.getValue("tables").jsonArray

        return tables.map { element ->
            val table = element.jsonObject

            val columns = table.array("columns").map { column ->
                val type = column.string("type")

                Column(
                    name = column.string("name"),
                    type = if (type == "BOOLEAN") "INTEGER" else type,
                    notNull = column.flag("notNull"),
                    primaryKey = column.flag("primaryKey"),
                    default = column.getValue("default").jsonPrimitive.contentOrNull,
                )
            }

            val foreignKeys = table.array("foreignKeys").map { key ->
                ForeignKey(
                    column = key.string("column"),
                    table = key.string("table"),
                    to = key.string("to"),
                    onDelete = key.string("onDelete"),
                )
            }

            val indexes = table.array("indexes")
                .filter { !it.flag("partial") }
                .map { index ->
                    Index(
                        columns = index.getValue("columns").jsonArray.map { it.jsonPrimitive.content },
                        unique = index.flag("unique"),
                    )
                }

            Table(
                name = table.string("name"),
                columns = columns,
                foreignKeys = foreignKeys.toSet(),
                indexes = indexes.toSet(),
            )
        }
    }

    private fun JsonObject.array(key: String): List<JsonObject> = getValue(key).jsonArray.map(JsonElement::jsonObject)

    private fun JsonObject.string(key: String): String = getValue(key).jsonPrimitive.content

    private fun JsonObject.flag(key: String): Boolean = getValue(key).jsonPrimitive.boolean

    private companion object {
        const val HINT = "enum に case を足したら、トリガーを作り直す"

        val ICON_ID = id(1)
        val WALLET_ID = id(2)
        val TO_WALLET_ID = id(3)
        val CATEGORY_ID = id(4)

        const val TIMESTAMPS = "'2026-10-12T00:00:00Z', '2026-10-12T00:00:00Z'"

        const val INSERT_ICON = """
            INSERT INTO icon (id, emoji, text, color, created_at, updated_at)
            VALUES (?, '🎯', NULL, '#000000', $TIMESTAMPS)
        """

        val INSERT_WALLET = """
            INSERT INTO wallet (id, name, kind, icon_id, initial_balance, sort_order, created_at, updated_at)
            VALUES (?, '財布', ?, '$ICON_ID', 0, 0, $TIMESTAMPS)
        """

        val INSERT_CATEGORY = """
            INSERT INTO category (id, kind, name, icon_id, sort_order, created_at, updated_at)
            VALUES (?, ?, '食費', '$ICON_ID', 0, $TIMESTAMPS)
        """

        val INSERT_RECURRING = """
            INSERT INTO recurring (id, type, amount, category_id, wallet_id, frequency, month, day, start_date, created_at, updated_at)
            VALUES (?, 'expense', 1, '$CATEGORY_ID', '$WALLET_ID', ?, ?, 1, '2026-10-12', $TIMESTAMPS)
        """

        val INSERT_ENTRY = """
            INSERT INTO entry (id, type, amount, category_id, wallet_id, to_wallet_id, date, created_at, updated_at)
            VALUES (?, ?, 1, ?, '$WALLET_ID', ?, '2026-10-12', $TIMESTAMPS)
        """

        const val TABLE_QUERY = """
            SELECT name FROM sqlite_master
            WHERE type = 'table' AND name NOT LIKE 'sqlite_%' AND name <> 'room_master_table'
        """

        const val TRIGGER_QUERY = "SELECT name FROM sqlite_master WHERE type = 'trigger'"

        fun id(number: Int): String = "00000000-0000-4000-8000-%012d".format(number)
    }
}

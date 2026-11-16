package com.yossibank.kakeibot.store.database

import androidx.room.RoomDatabase
import androidx.sqlite.SQLiteConnection
import androidx.sqlite.execSQL

internal object AppDatabaseChecks : RoomDatabase.Callback() {
    private val walletKinds = listOf(
        "cash",
        "bank",
        "card",
        "emoney",
        "point",
        "other",
        "investment",
        "loan",
    )

    private val categoryKinds = listOf(
        "expense",
        "income",
    )

    private val entryKinds = listOf(
        "expense",
        "income",
        "transfer",
    )

    private val frequencies = listOf(
        "monthly",
        "yearly",
    )

    private val movement = listOf(
        "NEW.type IN ${entryKinds.sqlList()}",
        "(NEW.type = 'transfer') = (NEW.category_id IS NULL)",
        "(NEW.type = 'transfer') = (NEW.to_wallet_id IS NOT NULL)",
        "NEW.to_wallet_id IS NULL OR NEW.to_wallet_id <> NEW.wallet_id",
    )

    private val conditions = mapOf(
        "icon" to listOf(
            "length(NEW.text) <= 3",
            "NEW.emoji IS NOT NULL OR NEW.text IS NOT NULL OR NEW.glyph IS NOT NULL",
        ),
        "wallet" to listOf(
            "NEW.kind IN ${walletKinds.sqlList()}",
        ),
        "category" to listOf(
            "NEW.kind IN ${categoryKinds.sqlList()}",
        ),
        "recurring" to movement + listOf(
            "NEW.amount >= 0",
            "NEW.frequency IN ${frequencies.sqlList()}",
            "NEW.month BETWEEN 1 AND 12",
            "NEW.day BETWEEN 1 AND 31",
            "NEW.closing_day BETWEEN 1 AND 31",
            "NEW.remind_days_before >= 0",
            "(NEW.frequency = 'yearly') = (NEW.month IS NOT NULL)",
            "NEW.closing_day IS NULL OR NEW.type = 'transfer'",
            "NEW.amount >= 1 OR NEW.closing_day IS NOT NULL",
        ),
        "entry" to movement + listOf(
            "NEW.amount >= 1",
            "(NEW.recurring_id IS NULL) = (NEW.recurring_date IS NULL)",
        ),
        "budget" to listOf(
            "NEW.amount >= 0",
        ),
        "template" to listOf(
            "NEW.type IN ${categoryKinds.sqlList()}",
            "NEW.amount >= 1",
        ),
        "entry_item" to listOf(
            "length(NEW.name) > 0",
            "NEW.quantity >= 1",
            "NEW.tax_rate IS NULL OR NEW.tax_rate IN (8, 10)",
        ),
        "adjustment" to listOf(
            "NEW.amount <> 0",
        ),
    )

    private val wholeMonthBudget = """
        NEW.category_id IS NULL AND EXISTS (
            SELECT 1 FROM budget
            WHERE category_id IS NULL AND from_month = NEW.from_month AND id <> %s
        )
    """.trimIndent()

    val statements: List<String>
        get() {
            val checks = conditions.flatMap { (table, conditions) ->
                val condition = conditions.joinToString(" AND ") { "($it)" }

                listOf("INSERT", "UPDATE").map { event ->
                    trigger(
                        name = "${table}_check_${event.lowercase()}",
                        event = event,
                        table = table,
                        condition = "NOT ($condition)",
                        message = "CHECK constraint failed: $table",
                    )
                }
            }

            val budget = listOf(
                "INSERT" to "NEW.id",
                "UPDATE" to "OLD.id",
            ).map { (event, id) ->
                trigger(
                    name = "budget_whole_month_${event.lowercase()}",
                    event = event,
                    table = "budget",
                    condition = wholeMonthBudget.format(id),
                    message = "UNIQUE constraint failed: budget.from_month",
                )
            }

            return checks + budget
        }

    override fun onCreate(connection: SQLiteConnection) {
        for (statement in statements) {
            connection.execSQL(statement)
        }
    }

    private fun trigger(
        name: String,
        event: String,
        table: String,
        condition: String,
        message: String,
    ): String = """
        CREATE TRIGGER $name BEFORE $event ON $table
        WHEN $condition
        BEGIN
            SELECT RAISE(ABORT, '$message');
        END
    """.trimIndent()

    private fun List<String>.sqlList(): String = joinToString(
        separator = ", ",
        prefix = "(",
        postfix = ")",
    ) { "'$it'" }
}

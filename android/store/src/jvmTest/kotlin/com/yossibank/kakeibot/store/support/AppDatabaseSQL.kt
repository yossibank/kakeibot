package com.yossibank.kakeibot.store.support

import androidx.room.immediateTransaction
import androidx.room.useReaderConnection
import androidx.room.useWriterConnection
import androidx.sqlite.SQLiteStatement
import com.yossibank.kakeibot.store.database.AppDatabase

suspend fun AppDatabase.execute(
    sql: String,
    vararg arguments: Any?,
) {
    useWriterConnection { connection ->
        connection.immediateTransaction {
            usePrepared(sql) { statement ->
                statement.bind(arguments.toList())
                statement.step()
            }
        }
    }
}

suspend fun AppDatabase.rows(
    sql: String,
    vararg arguments: Any?,
): List<Map<String, Any?>> = useReaderConnection { connection ->
    connection.usePrepared(sql) { statement ->
        statement.bind(arguments.toList())

        buildList {
            while (statement.step()) {
                add(statement.row())
            }
        }
    }
}

private fun SQLiteStatement.bind(arguments: List<Any?>) {
    for ((offset, argument) in arguments.withIndex()) {
        val index = offset + 1

        when (argument) {
            null -> bindNull(index)
            is String -> bindText(index, argument)
            is Int -> bindLong(index, argument.toLong())
            is Long -> bindLong(index, argument)
            else -> error("Unsupported argument: $argument")
        }
    }
}

private fun SQLiteStatement.row(): Map<String, Any?> = (0 until getColumnCount()).associate { index ->
    val value = when {
        isNull(index) -> null
        getColumnType(index) == SQLITE_INTEGER -> getLong(index)
        else -> getText(index)
    }

    getColumnName(index) to value
}

private const val SQLITE_INTEGER = 1

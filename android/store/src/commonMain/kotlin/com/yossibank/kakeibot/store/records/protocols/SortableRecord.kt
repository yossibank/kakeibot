package com.yossibank.kakeibot.store.records.protocols

import androidx.room.PooledConnection
import java.time.Instant

interface SortableRecord {
    val id: String
    val sortOrder: Int
    val updatedAt: String
}

fun nextSortOrder(maxOrder: Int?): Int = maxOrder?.let { it + 1 } ?: 0

internal suspend fun PooledConnection.reorder(
    table: String,
    ids: List<String>,
    notFound: Throwable,
    now: Instant,
) {
    for ((order, id) in ids.withIndex()) {
        val current = usePrepared("SELECT sort_order FROM $table WHERE id = ?") { statement ->
            statement.bindText(1, id)

            if (statement.step()) statement.getLong(0).toInt() else null
        } ?: throw notFound

        if (current == order) {
            continue
        }

        usePrepared("UPDATE $table SET sort_order = ?, updated_at = ? WHERE id = ?") { statement ->
            statement.bindLong(1, order.toLong())
            statement.bindText(2, now.storedValue)
            statement.bindText(3, id)
            statement.step()
        }
    }
}

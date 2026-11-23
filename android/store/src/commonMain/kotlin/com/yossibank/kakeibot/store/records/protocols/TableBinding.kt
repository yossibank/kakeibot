package com.yossibank.kakeibot.store.records.protocols

import com.yossibank.kakeibot.store.database.AppDatabase

internal class TableBinding<Value : Any>(
    val all: suspend AppDatabase.() -> List<Value>,
    val insert: suspend AppDatabase.(Value) -> Unit,
    val deleteAll: suspend AppDatabase.() -> Unit,
)

internal class TableColumn<Owner, Value : Any>(
    val table: TableBinding<Value>,
    val values: (Owner) -> List<Value>,
) {
    suspend fun insert(
        owner: Owner,
        into: AppDatabase,
    ) {
        for (value in values(owner)) {
            table.insert(into, value)
        }
    }
}

package com.yossibank.kakeibot.store.writes.methods

import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.records.protocols.HidableTable
import com.yossibank.kakeibot.store.records.protocols.SortableTable
import com.yossibank.kakeibot.store.records.protocols.reorder
import com.yossibank.kakeibot.store.records.values.databaseValue
import java.time.Instant

suspend fun <Value : Any> AppDatabase.reorder(
    table: SortableTable<Value>,
    ids: List<Identifier<Value>>,
    at: Instant,
) {
    write {
        reorder(
            table = table.name,
            ids = ids.map { it.databaseValue },
            notFound = table.notFound(),
            now = at,
        )
    }
}

suspend fun <Value : Any> AppDatabase.setHidden(
    table: HidableTable<Value>,
    id: Identifier<Value>,
    isHidden: Boolean,
    at: Instant,
) {
    write {
        table.hide(
            database = this@setHidden,
            id = id,
            isHidden = isHidden,
            at = at,
        )
    }
}

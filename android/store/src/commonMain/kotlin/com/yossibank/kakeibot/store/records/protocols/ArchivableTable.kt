package com.yossibank.kakeibot.store.records.protocols

import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import java.time.Instant

interface ArchivableTable<Value : Any> : HidableTable<Value> {
    suspend fun find(
        database: AppDatabase,
        id: Identifier<Value>,
    ): Value?

    suspend fun update(
        database: AppDatabase,
        value: Value,
    )

    fun archived(
        value: Value,
        archivedAt: Instant?,
        at: Instant,
    ): Value

    override suspend fun hide(
        database: AppDatabase,
        id: Identifier<Value>,
        isHidden: Boolean,
        at: Instant,
    ) {
        val value = find(database, id) ?: throw notFound()

        update(database, archived(value, if (isHidden) at else null, at))
    }
}

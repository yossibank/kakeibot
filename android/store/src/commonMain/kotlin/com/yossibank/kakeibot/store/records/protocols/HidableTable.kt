package com.yossibank.kakeibot.store.records.protocols

import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import java.time.Instant

interface HidableTable<Value : Any> : SortableTable<Value> {
    suspend fun hide(
        database: AppDatabase,
        id: Identifier<Value>,
        isHidden: Boolean,
        at: Instant,
    )
}

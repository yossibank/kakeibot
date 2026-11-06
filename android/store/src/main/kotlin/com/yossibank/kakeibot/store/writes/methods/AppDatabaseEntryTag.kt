package com.yossibank.kakeibot.store.writes.methods

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.category.EntryTag
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.EntryTagRecord
import com.yossibank.kakeibot.store.records.rows.entryTag
import com.yossibank.kakeibot.store.records.values.databaseValue

internal suspend fun AppDatabase.tag(
    id: Identifier<EntryTag>?,
    belongsTo: Identifier<EntryCategory>?,
): Boolean {
    id ?: return true

    val tag = tagDao().find(id.databaseValue)?.decoded(EntryTagRecord::entryTag)

    return tag?.categoryId == belongsTo
}

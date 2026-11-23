package com.yossibank.kakeibot.store.writes.methods

import com.yossibank.kakeibot.core.concepts.icon.IconDraft
import com.yossibank.kakeibot.core.concepts.icon.ShelfIcon
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.protocols.nextSortOrder
import com.yossibank.kakeibot.store.records.protocols.reorder
import com.yossibank.kakeibot.store.records.rows.IconRecord
import com.yossibank.kakeibot.store.records.rows.ShelfIconRecord
import com.yossibank.kakeibot.store.records.rows.icon
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.rows.shelfIcon
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.writes.types.Deletion
import java.time.Instant

enum class ShelfIconWriteError {
    shelfIconNotFound,
    iconNotFound,
}

class ShelfIconWriteException(
    val error: ShelfIconWriteError,
) : Exception(error.name)

suspend fun AppDatabase.deleteShelfIcon(id: Identifier<ShelfIcon>): Deletion = write {
    val shelfIcon =
        findShelfIcon(id) ?: throw ShelfIconWriteException(ShelfIconWriteError.shelfIconNotFound)

    shelfIconDao().delete(id.databaseValue)

    Deletion(shelfIcons = listOf(shelfIcon))
}

private suspend fun AppDatabase.findShelfIcon(id: Identifier<ShelfIcon>): ShelfIcon? =
    shelfIconDao().find(id.databaseValue)?.decoded(ShelfIconRecord::shelfIcon)

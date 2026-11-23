package com.yossibank.kakeibot.store.writes.types

import com.yossibank.kakeibot.core.concepts.icon.IconDraft
import com.yossibank.kakeibot.core.concepts.icon.ShelfIcon
import com.yossibank.kakeibot.store.records.protocols.IconBackedTable
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.ShelfIconRecord
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.rows.shelfIcon
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.writes.methods.ShelfIconWriteError
import com.yossibank.kakeibot.store.writes.methods.ShelfIconWriteException

val ShelfIconTable = IconBackedTable<ShelfIcon, IconDraft>(
    name = "shelf_icon",
    notFoundError = { ShelfIconWriteException(ShelfIconWriteError.shelfIconNotFound) },
    iconNotFoundError = { ShelfIconWriteException(ShelfIconWriteError.iconNotFound) },
    iconId = { it.iconId },
    find = { shelfIconDao().find(it.databaseValue)?.decoded(ShelfIconRecord::shelfIcon) },
    insert = { shelfIconDao().insert(it.record()) },
    update = { shelfIconDao().update(it.record()) },
    maxSortOrder = { shelfIconDao().maxSortOrder() },
    archived = { value, archivedAt, at -> value.copy(archivedAt = archivedAt, updatedAt = at) },
)

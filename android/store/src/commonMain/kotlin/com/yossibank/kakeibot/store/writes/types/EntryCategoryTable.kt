package com.yossibank.kakeibot.store.writes.types

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.category.EntryCategoryDraft
import com.yossibank.kakeibot.store.records.protocols.IconBackedTable
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.EntryCategoryRecord
import com.yossibank.kakeibot.store.records.rows.entryCategory
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.writes.methods.CategoryWriteError
import com.yossibank.kakeibot.store.writes.methods.CategoryWriteException

val EntryCategoryTable = IconBackedTable<EntryCategory, EntryCategoryDraft>(
    name = "category",
    notFoundError = { CategoryWriteException(CategoryWriteError.categoryNotFound) },
    iconNotFoundError = { CategoryWriteException(CategoryWriteError.iconNotFound) },
    iconId = { it.iconId },
    find = { categoryDao().find(it.databaseValue)?.decoded(EntryCategoryRecord::entryCategory) },
    insert = { categoryDao().insert(it.record()) },
    update = { categoryDao().update(it.record()) },
    maxSortOrder = { categoryDao().maxSortOrderWithoutWallet(it.kind.rawValue) },
    archived = { value, archivedAt, at -> value.copy(archivedAt = archivedAt, updatedAt = at) },
)

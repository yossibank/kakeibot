package com.yossibank.kakeibot.store.queries.types

import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.entryListUpdates
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged

internal fun <Part, Value> AppDatabase.entryListJoin(
    part: Flow<Part>,
    join: (EntryList, Part) -> Value,
): Flow<Value> = combine(
    entryListUpdates(),
    part.distinctUntilChanged(),
    join,
).distinctUntilChanged()

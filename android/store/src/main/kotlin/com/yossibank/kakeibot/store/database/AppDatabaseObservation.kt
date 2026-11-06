package com.yossibank.kakeibot.store.database

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

internal fun <Value> AppDatabase.observation(
    vararg tables: String,
    fetch: suspend AppDatabase.() -> Value,
): Flow<Value> = invalidationTracker
    .createFlow(*tables)
    .map {
        read {
            fetch()
        }
    }

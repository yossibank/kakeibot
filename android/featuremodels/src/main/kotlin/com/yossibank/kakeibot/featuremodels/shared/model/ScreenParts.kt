package com.yossibank.kakeibot.featuremodels.shared.model

import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.entryListUpdates
import com.yossibank.kakeibot.store.queries.types.EntryList
import kotlinx.coroutines.flow.Flow

class ScreenParts internal constructor(
    internal val database: AppDatabase,
    val clock: ScreenClock,
    internal val entryList: Flow<EntryList>,
) {
    constructor(
        database: AppDatabase,
        clock: ScreenClock,
    ) : this(
        database = database,
        clock = clock,
        entryList = database.entryListUpdates(),
    )
}

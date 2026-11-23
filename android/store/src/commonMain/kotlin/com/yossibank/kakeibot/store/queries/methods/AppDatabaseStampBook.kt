package com.yossibank.kakeibot.store.queries.methods

import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.observation
import com.yossibank.kakeibot.store.database.read
import com.yossibank.kakeibot.store.queries.types.StampBook
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.CalendarStampRecord
import com.yossibank.kakeibot.store.records.rows.calendarStamp
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged

fun AppDatabase.stampBookUpdates(): Flow<StampBook> = observation(
    "calendar_stamp",
    "icon",
) {
    fetchStampBook()
}.distinctUntilChanged()

suspend fun AppDatabase.stampBook(): StampBook = read {
    fetchStampBook()
}

private suspend fun AppDatabase.fetchStampBook(): StampBook {
    val stamps = calendarStampDao()
        .all()
        .map { it.decoded(CalendarStampRecord::calendarStamp) }

    return StampBook(
        stamps = stamps.associateBy { it.date },
        icons = fetchIcons(stamps.map { it.iconId }),
    )
}

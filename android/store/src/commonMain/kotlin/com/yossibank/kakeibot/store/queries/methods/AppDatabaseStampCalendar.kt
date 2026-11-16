package com.yossibank.kakeibot.store.queries.methods

import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.observation
import com.yossibank.kakeibot.store.database.read
import com.yossibank.kakeibot.store.queries.types.StampCalendar
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.CalendarStampRecord
import com.yossibank.kakeibot.store.records.rows.calendarStamp
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged

fun AppDatabase.stampCalendarUpdates(): Flow<StampCalendar> = observation(
    "calendar_stamp",
    "icon",
) {
    fetchStampCalendar()
}.distinctUntilChanged()

suspend fun AppDatabase.stampCalendar(): StampCalendar = read {
    fetchStampCalendar()
}

private suspend fun AppDatabase.fetchStampCalendar(): StampCalendar {
    val stamps = calendarStampDao()
        .all()
        .map { it.decoded(CalendarStampRecord::calendarStamp) }

    return StampCalendar(
        stamps = stamps.associateBy { it.date },
        icons = fetchIcons(stamps.map { it.iconId }),
    )
}

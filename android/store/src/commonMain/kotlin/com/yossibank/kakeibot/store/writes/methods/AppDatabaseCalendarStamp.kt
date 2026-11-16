package com.yossibank.kakeibot.store.writes.methods

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.icon.CalendarStamp
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.values.databaseValue
import java.time.Instant

suspend fun AppDatabase.stamp(
    iconId: Identifier<Icon>,
    on: LocalDate,
    at: Instant,
): CalendarStamp = write {
    calendarStampDao().deleteOn(on.databaseValue)

    val stamp = CalendarStamp(
        date = on,
        iconId = iconId,
        createdAt = at,
    )

    calendarStampDao().insert(stamp.record())

    stamp
}

suspend fun AppDatabase.removeStamp(on: LocalDate) {
    write {
        calendarStampDao().deleteOn(on.databaseValue)
    }
}

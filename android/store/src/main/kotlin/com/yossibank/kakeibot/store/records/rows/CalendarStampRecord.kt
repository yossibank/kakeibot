package com.yossibank.kakeibot.store.records.rows

import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.Insert
import androidx.room.PrimaryKey
import androidx.room.Query
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.icon.CalendarStamp
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.records.protocols.storedInstant
import com.yossibank.kakeibot.store.records.protocols.storedValue
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.records.values.fromDatabaseValue

@Entity(
    tableName = "calendar_stamp",
    foreignKeys = [
        ForeignKey(
            entity = IconRecord::class,
            parentColumns = ["id"],
            childColumns = ["icon_id"],
        ),
    ],
    indices = [
        Index(
            value = ["date"],
            name = "calendar_stamp_date",
            unique = true,
        ),
    ],
)
data class CalendarStampRecord(
    @PrimaryKey val id: String,
    val date: String,
    @ColumnInfo(name = "icon_id") val iconId: String,
    @ColumnInfo(name = "created_at") val createdAt: String,
)

@Dao
interface CalendarStampRecordDao {
    @Insert
    suspend fun insert(record: CalendarStampRecord)

    @Query("SELECT * FROM calendar_stamp ORDER BY id")
    suspend fun all(): List<CalendarStampRecord>

    @Query("DELETE FROM calendar_stamp")
    suspend fun deleteAll()

    @Query("DELETE FROM calendar_stamp WHERE date = :date")
    suspend fun deleteOn(date: String)

    @Query("SELECT COUNT(*) FROM calendar_stamp")
    suspend fun count(): Int
}

fun CalendarStamp.record(): CalendarStampRecord = CalendarStampRecord(
    id = id.databaseValue,
    date = date.databaseValue,
    iconId = iconId.databaseValue,
    createdAt = createdAt.storedValue,
)

fun CalendarStampRecord.calendarStamp(): CalendarStamp? {
    val id = Identifier.fromDatabaseValue<CalendarStamp>(id) ?: return null
    val date = LocalDate.fromDatabaseValue(date) ?: return null
    val iconId = Identifier.fromDatabaseValue<Icon>(iconId) ?: return null
    val createdAt = storedInstant(createdAt) ?: return null

    return CalendarStamp(
        id = id,
        date = date,
        iconId = iconId,
        createdAt = createdAt,
    )
}

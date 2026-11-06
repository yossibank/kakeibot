package com.yossibank.kakeibot.store.records.rows

import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Entity
import androidx.room.Insert
import androidx.room.PrimaryKey
import androidx.room.Query
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.NoSpendDay
import com.yossibank.kakeibot.store.records.protocols.storedInstant
import com.yossibank.kakeibot.store.records.protocols.storedValue
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.records.values.fromDatabaseValue

@Entity(tableName = "no_spend_day")
data class NoSpendDayRecord(
    @PrimaryKey val date: String,
    @ColumnInfo(name = "created_at") val createdAt: String,
)

@Dao
interface NoSpendDayRecordDao {
    @Insert
    suspend fun insert(record: NoSpendDayRecord)

    @Query("SELECT * FROM no_spend_day ORDER BY date")
    suspend fun all(): List<NoSpendDayRecord>

    @Query("DELETE FROM no_spend_day")
    suspend fun deleteAll()

    @Query("SELECT * FROM no_spend_day WHERE date >= :start")
    suspend fun since(start: String): List<NoSpendDayRecord>
}

fun NoSpendDay.record(): NoSpendDayRecord = NoSpendDayRecord(
    date = date.databaseValue,
    createdAt = createdAt.storedValue,
)

fun NoSpendDayRecord.noSpendDay(): NoSpendDay? {
    val date = LocalDate.fromDatabaseValue(date) ?: return null
    val createdAt = storedInstant(createdAt) ?: return null

    return NoSpendDay(
        date = date,
        createdAt = createdAt,
    )
}

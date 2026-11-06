package com.yossibank.kakeibot.store.records.rows

import androidx.room.Dao
import androidx.room.Entity
import androidx.room.Insert
import androidx.room.PrimaryKey
import androidx.room.Query
import androidx.room.Upsert
import com.yossibank.kakeibot.core.concepts.setting.Setting

@Entity(tableName = "setting")
data class SettingRecord(
    @PrimaryKey val key: String,
    val value: String,
)

@Dao
interface SettingRecordDao {
    @Insert
    suspend fun insert(record: SettingRecord)

    @Upsert
    suspend fun save(record: SettingRecord)

    @Query("SELECT * FROM setting WHERE `key` = :key")
    suspend fun find(key: String): SettingRecord?

    @Query("SELECT * FROM setting ORDER BY `key`")
    suspend fun all(): List<SettingRecord>

    @Query("SELECT * FROM setting WHERE `key` IN (:keys) ORDER BY `key`")
    suspend fun all(keys: List<String>): List<SettingRecord>

    @Query("DELETE FROM setting WHERE `key` = :key")
    suspend fun delete(key: String)
}

fun Setting.record(): SettingRecord = SettingRecord(
    key = key.rawValue,
    value = value,
)

fun SettingRecord.setting(): Setting? {
    val key = Setting.Key.of(key) ?: return null

    return Setting(
        key = key,
        value = value,
    )
}

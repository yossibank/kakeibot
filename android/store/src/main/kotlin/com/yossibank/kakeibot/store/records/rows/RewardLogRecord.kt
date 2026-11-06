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
import com.yossibank.kakeibot.core.concepts.reward.RewardLog
import com.yossibank.kakeibot.core.concepts.reward.RewardRule
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.records.protocols.storedInstant
import com.yossibank.kakeibot.store.records.protocols.storedValue
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.records.values.fromDatabaseValue

@Entity(
    tableName = "reward_log",
    foreignKeys = [
        ForeignKey(
            entity = RewardRuleRecord::class,
            parentColumns = ["id"],
            childColumns = ["rule_id"],
        ),
    ],
    indices = [
        Index(
            value = ["rule_id", "date"],
            unique = true,
        ),
    ],
)
data class RewardLogRecord(
    @PrimaryKey val id: String,
    @ColumnInfo(name = "rule_id") val ruleId: String,
    val date: String,
    val amount: Int,
    @ColumnInfo(name = "created_at") val createdAt: String,
)

@Dao
interface RewardLogRecordDao {
    @Insert
    suspend fun insert(record: RewardLogRecord)

    @Query("SELECT * FROM reward_log ORDER BY id")
    suspend fun all(): List<RewardLogRecord>

    @Query("DELETE FROM reward_log")
    suspend fun deleteAll()
}

fun RewardLog.record(): RewardLogRecord = RewardLogRecord(
    id = id.databaseValue,
    ruleId = ruleId.databaseValue,
    date = date.databaseValue,
    amount = amount,
    createdAt = createdAt.storedValue,
)

fun RewardLogRecord.rewardLog(): RewardLog? {
    val id = Identifier.fromDatabaseValue<RewardLog>(id) ?: return null
    val ruleId = Identifier.fromDatabaseValue<RewardRule>(ruleId) ?: return null
    val date = LocalDate.fromDatabaseValue(date) ?: return null
    val createdAt = storedInstant(createdAt) ?: return null

    return RewardLog(
        id = id,
        ruleId = ruleId,
        date = date,
        amount = amount,
        createdAt = createdAt,
    )
}

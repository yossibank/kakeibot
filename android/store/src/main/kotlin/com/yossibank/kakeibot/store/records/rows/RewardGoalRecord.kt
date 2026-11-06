package com.yossibank.kakeibot.store.records.rows

import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Insert
import androidx.room.PrimaryKey
import androidx.room.Query
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.reward.RewardGoal
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.records.protocols.storedInstant
import com.yossibank.kakeibot.store.records.protocols.storedValue
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.records.values.fromDatabaseValue

@Entity(
    tableName = "reward_goal",
    foreignKeys = [
        ForeignKey(
            entity = EntryRecord::class,
            parentColumns = ["id"],
            childColumns = ["entry_id"],
        ),
    ],
)
data class RewardGoalRecord(
    @PrimaryKey val id: String,
    val name: String,
    @ColumnInfo(name = "target_amount") val targetAmount: Int,
    @ColumnInfo(name = "purchased_at") val purchasedAt: String?,
    @ColumnInfo(name = "entry_id") val entryId: String?,
    @ColumnInfo(name = "created_at") val createdAt: String,
    @ColumnInfo(name = "updated_at") val updatedAt: String,
)

@Dao
interface RewardGoalRecordDao {
    @Insert
    suspend fun insert(record: RewardGoalRecord)

    @Query("SELECT * FROM reward_goal ORDER BY id")
    suspend fun all(): List<RewardGoalRecord>

    @Query("DELETE FROM reward_goal")
    suspend fun deleteAll()
}

fun RewardGoal.record(): RewardGoalRecord = RewardGoalRecord(
    id = id.databaseValue,
    name = name,
    targetAmount = targetAmount,
    purchasedAt = purchasedAt?.storedValue,
    entryId = entryId?.databaseValue,
    createdAt = createdAt.storedValue,
    updatedAt = updatedAt.storedValue,
)

fun RewardGoalRecord.rewardGoal(): RewardGoal? {
    val id = Identifier.fromDatabaseValue<RewardGoal>(id) ?: return null
    val purchasedAt = purchasedAt?.let { storedInstant(it) ?: return null }
    val entryId = entryId?.let { Identifier.fromDatabaseValue<Entry>(it) ?: return null }
    val createdAt = storedInstant(createdAt) ?: return null
    val updatedAt = storedInstant(updatedAt) ?: return null

    return RewardGoal(
        id = id,
        name = name,
        targetAmount = targetAmount,
        purchasedAt = purchasedAt,
        entryId = entryId,
        createdAt = createdAt,
        updatedAt = updatedAt,
    )
}

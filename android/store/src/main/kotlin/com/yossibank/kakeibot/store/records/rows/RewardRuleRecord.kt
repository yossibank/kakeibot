package com.yossibank.kakeibot.store.records.rows

import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Insert
import androidx.room.PrimaryKey
import androidx.room.Query
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.reward.RewardRule
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.records.protocols.SortableRecord
import com.yossibank.kakeibot.store.records.protocols.storedInstant
import com.yossibank.kakeibot.store.records.protocols.storedValue
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.records.values.fromDatabaseValue

@Entity(
    tableName = "reward_rule",
    foreignKeys = [
        ForeignKey(
            entity = IconRecord::class,
            parentColumns = ["id"],
            childColumns = ["icon_id"],
        ),
    ],
)
data class RewardRuleRecord(
    @PrimaryKey override val id: String,
    val name: String,
    val amount: Int,
    @ColumnInfo(name = "icon_id") val iconId: String,
    @ColumnInfo(name = "is_active") val isActive: Boolean,
    @ColumnInfo(name = "sort_order") override val sortOrder: Int,
    @ColumnInfo(name = "created_at") val createdAt: String,
    @ColumnInfo(name = "updated_at") override val updatedAt: String,
) : SortableRecord

@Dao
interface RewardRuleRecordDao {
    @Insert
    suspend fun insert(record: RewardRuleRecord)

    @Query("SELECT * FROM reward_rule ORDER BY id")
    suspend fun all(): List<RewardRuleRecord>

    @Query("DELETE FROM reward_rule")
    suspend fun deleteAll()
}

fun RewardRule.record(): RewardRuleRecord = RewardRuleRecord(
    id = id.databaseValue,
    name = name,
    amount = amount,
    iconId = iconId.databaseValue,
    isActive = isActive,
    sortOrder = sortOrder,
    createdAt = createdAt.storedValue,
    updatedAt = updatedAt.storedValue,
)

fun RewardRuleRecord.rewardRule(): RewardRule? {
    val id = Identifier.fromDatabaseValue<RewardRule>(id) ?: return null
    val iconId = Identifier.fromDatabaseValue<Icon>(iconId) ?: return null
    val createdAt = storedInstant(createdAt) ?: return null
    val updatedAt = storedInstant(updatedAt) ?: return null

    return RewardRule(
        id = id,
        name = name,
        amount = amount,
        iconId = iconId,
        isActive = isActive,
        sortOrder = sortOrder,
        createdAt = createdAt,
        updatedAt = updatedAt,
    )
}

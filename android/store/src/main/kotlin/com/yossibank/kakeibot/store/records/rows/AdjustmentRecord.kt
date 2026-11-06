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
import com.yossibank.kakeibot.core.concepts.wallet.Adjustment
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.records.protocols.storedInstant
import com.yossibank.kakeibot.store.records.protocols.storedValue
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.records.values.fromDatabaseValue

@Entity(
    tableName = "adjustment",
    foreignKeys = [
        ForeignKey(
            entity = WalletRecord::class,
            parentColumns = ["id"],
            childColumns = ["wallet_id"],
        ),
    ],
    indices = [
        Index(
            value = ["wallet_id"],
            name = "adjustment_wallet_id",
        ),
    ],
)
data class AdjustmentRecord(
    @PrimaryKey val id: String,
    @ColumnInfo(name = "wallet_id") val walletId: String,
    val date: String,
    val amount: Long,
    @ColumnInfo(name = "created_at") val createdAt: String,
    @ColumnInfo(name = "updated_at") val updatedAt: String,
)

@Dao
interface AdjustmentRecordDao {
    @Insert
    suspend fun insert(record: AdjustmentRecord)

    @Query("SELECT * FROM adjustment ORDER BY id")
    suspend fun all(): List<AdjustmentRecord>
}

fun Adjustment.record(): AdjustmentRecord = AdjustmentRecord(
    id = id.databaseValue,
    walletId = walletId.databaseValue,
    date = date.databaseValue,
    amount = amount,
    createdAt = createdAt.storedValue,
    updatedAt = updatedAt.storedValue,
)

fun AdjustmentRecord.adjustment(): Adjustment? {
    val id = Identifier.fromDatabaseValue<Adjustment>(id) ?: return null
    val walletId = Identifier.fromDatabaseValue<Wallet>(walletId) ?: return null
    val date = LocalDate.fromDatabaseValue(date) ?: return null
    val createdAt = storedInstant(createdAt) ?: return null
    val updatedAt = storedInstant(updatedAt) ?: return null

    return Adjustment(
        id = id,
        walletId = walletId,
        date = date,
        amount = amount,
        createdAt = createdAt,
        updatedAt = updatedAt,
    )
}

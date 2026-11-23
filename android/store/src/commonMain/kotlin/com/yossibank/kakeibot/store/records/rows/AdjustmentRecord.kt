package com.yossibank.kakeibot.store.records.rows

import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import androidx.room.Query
import com.yossibank.kakeibot.core.concepts.wallet.Adjustment
import com.yossibank.kakeibot.store.records.protocols.InsertableDao
import com.yossibank.kakeibot.store.records.protocols.TableBinding
import com.yossibank.kakeibot.store.records.protocols.WalletDatedRecord
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.protocols.decodedFields
import com.yossibank.kakeibot.store.records.protocols.walletDatedColumns

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
    @PrimaryKey override val id: String,
    @ColumnInfo(name = "wallet_id") override val walletId: String,
    override val date: String,
    val amount: Long,
    @ColumnInfo(name = "created_at") override val createdAt: String,
    @ColumnInfo(name = "updated_at") override val updatedAt: String,
) : WalletDatedRecord

@Dao
interface AdjustmentRecordDao : InsertableDao<AdjustmentRecord> {
    @Query("SELECT * FROM adjustment ORDER BY id")
    suspend fun all(): List<AdjustmentRecord>

    @Query("DELETE FROM adjustment")
    suspend fun deleteAll()

    @Query("SELECT * FROM adjustment ORDER BY date, created_at")
    suspend fun inDateOrder(): List<AdjustmentRecord>

    @Query("SELECT * FROM adjustment WHERE id = :id")
    suspend fun find(id: String): AdjustmentRecord?

    @Query("DELETE FROM adjustment WHERE id = :id")
    suspend fun delete(id: String)

    @Query("SELECT COUNT(*) FROM adjustment")
    suspend fun count(): Int

    @Query("SELECT * FROM adjustment WHERE wallet_id = :walletId")
    suspend fun ofWallet(walletId: String): List<AdjustmentRecord>

    @Query("SELECT COUNT(*) FROM adjustment WHERE wallet_id = :walletId")
    suspend fun countOfWallet(walletId: String): Int

    @Query("DELETE FROM adjustment WHERE wallet_id = :walletId")
    suspend fun deleteOfWallet(walletId: String)
}

fun Adjustment.record(): AdjustmentRecord =
    walletDatedColumns(id, walletId, date, createdAt, updatedAt).run {
        AdjustmentRecord(id, walletId, date, amount, createdAt, updatedAt)
    }

fun AdjustmentRecord.adjustment(): Adjustment? = decodedFields<Adjustment>()?.run {
    Adjustment(id, walletId, date, amount, createdAt, updatedAt)
}

internal val adjustmentTable = TableBinding<Adjustment>(
    all = { adjustmentDao().all().map { it.decoded(AdjustmentRecord::adjustment) } },
    insert = { adjustmentDao().insert(it.record()) },
    deleteAll = { adjustmentDao().deleteAll() },
)

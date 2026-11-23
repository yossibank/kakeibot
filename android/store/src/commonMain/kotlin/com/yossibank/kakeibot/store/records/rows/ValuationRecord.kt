package com.yossibank.kakeibot.store.records.rows

import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import androidx.room.Query
import com.yossibank.kakeibot.core.concepts.wallet.Valuation
import com.yossibank.kakeibot.store.records.protocols.InsertableDao
import com.yossibank.kakeibot.store.records.protocols.TableBinding
import com.yossibank.kakeibot.store.records.protocols.WalletDatedRecord
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.protocols.decodedFields
import com.yossibank.kakeibot.store.records.protocols.walletDatedColumns

@Entity(
    tableName = "valuation",
    foreignKeys = [
        ForeignKey(
            entity = WalletRecord::class,
            parentColumns = ["id"],
            childColumns = ["wallet_id"],
        ),
    ],
    indices = [
        Index(
            value = ["wallet_id", "date"],
            unique = true,
        ),
    ],
)
data class ValuationRecord(
    @PrimaryKey override val id: String,
    @ColumnInfo(name = "wallet_id") override val walletId: String,
    override val date: String,
    val amount: Int,
    @ColumnInfo(name = "created_at") override val createdAt: String,
    @ColumnInfo(name = "updated_at") override val updatedAt: String,
) : WalletDatedRecord

@Dao
interface ValuationRecordDao : InsertableDao<ValuationRecord> {
    @Query("SELECT * FROM valuation ORDER BY id")
    suspend fun all(): List<ValuationRecord>

    @Query("DELETE FROM valuation")
    suspend fun deleteAll()

    @Query("SELECT COUNT(*) FROM valuation")
    suspend fun count(): Int

    @Query("SELECT * FROM valuation WHERE id = :id")
    suspend fun find(id: String): ValuationRecord?

    @Query("DELETE FROM valuation WHERE id = :id")
    suspend fun delete(id: String)

    @Query("DELETE FROM valuation WHERE wallet_id = :walletId AND date = :date")
    suspend fun deleteOn(
        walletId: String,
        date: String,
    )

    @Query("SELECT * FROM valuation WHERE wallet_id = :walletId")
    suspend fun ofWallet(walletId: String): List<ValuationRecord>

    @Query("SELECT COUNT(*) FROM valuation WHERE wallet_id = :walletId")
    suspend fun countOfWallet(walletId: String): Int

    @Query("DELETE FROM valuation WHERE wallet_id = :walletId")
    suspend fun deleteOfWallet(walletId: String)
}

fun Valuation.record(): ValuationRecord =
    walletDatedColumns(id, walletId, date, createdAt, updatedAt).run {
        ValuationRecord(id, walletId, date, amount, createdAt, updatedAt)
    }

fun ValuationRecord.valuation(): Valuation? = decodedFields<Valuation>()?.run {
    Valuation(id, walletId, date, amount, createdAt, updatedAt)
}

internal val valuationTable = TableBinding<Valuation>(
    all = { valuationDao().all().map { it.decoded(ValuationRecord::valuation) } },
    insert = { valuationDao().insert(it.record()) },
    deleteAll = { valuationDao().deleteAll() },
)

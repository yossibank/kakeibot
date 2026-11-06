package com.yossibank.kakeibot.store.records.rows

import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Insert
import androidx.room.PrimaryKey
import androidx.room.Query
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.records.protocols.ArchivableRecord
import com.yossibank.kakeibot.store.records.protocols.storedInstant
import com.yossibank.kakeibot.store.records.protocols.storedValue
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.records.values.fromDatabaseValue

@Entity(
    tableName = "wallet",
    foreignKeys = [
        ForeignKey(
            entity = IconRecord::class,
            parentColumns = ["id"],
            childColumns = ["icon_id"],
        ),
    ],
)
data class WalletRecord(
    @PrimaryKey override val id: String,
    val name: String,
    val kind: String,
    @ColumnInfo(name = "icon_id") val iconId: String,
    @ColumnInfo(name = "initial_balance") val initialBalance: Int,
    @ColumnInfo(name = "sort_order") override val sortOrder: Int,
    @ColumnInfo(name = "archived_at") override val archivedAt: String?,
    @ColumnInfo(name = "created_at") val createdAt: String,
    @ColumnInfo(name = "updated_at") override val updatedAt: String,
    @ColumnInfo(name = "loan_amount") val loanAmount: Int?,
) : ArchivableRecord

@Dao
interface WalletRecordDao {
    @Insert
    suspend fun insert(record: WalletRecord)

    @Query("SELECT * FROM wallet WHERE id = :id")
    suspend fun find(id: String): WalletRecord?

    @Query("SELECT * FROM wallet ORDER BY id")
    suspend fun all(): List<WalletRecord>

    @Query("DELETE FROM wallet")
    suspend fun deleteAll()

    @Query("SELECT COUNT(*) FROM wallet")
    suspend fun count(): Int
}

fun Wallet.record(): WalletRecord = WalletRecord(
    id = id.databaseValue,
    name = name,
    kind = kind.rawValue,
    iconId = iconId.databaseValue,
    initialBalance = initialBalance,
    sortOrder = sortOrder,
    archivedAt = archivedAt?.storedValue,
    createdAt = createdAt.storedValue,
    updatedAt = updatedAt.storedValue,
    loanAmount = loanAmount,
)

fun WalletRecord.wallet(): Wallet? {
    val id = Identifier.fromDatabaseValue<Wallet>(id) ?: return null
    val kind = Wallet.Kind.of(kind) ?: return null
    val iconId = Identifier.fromDatabaseValue<Icon>(iconId) ?: return null
    val archivedAt = archivedAt?.let { storedInstant(it) ?: return null }
    val createdAt = storedInstant(createdAt) ?: return null
    val updatedAt = storedInstant(updatedAt) ?: return null

    return Wallet(
        id = id,
        name = name,
        kind = kind,
        iconId = iconId,
        initialBalance = initialBalance,
        loanAmount = loanAmount,
        sortOrder = sortOrder,
        archivedAt = archivedAt,
        createdAt = createdAt,
        updatedAt = updatedAt,
    )
}

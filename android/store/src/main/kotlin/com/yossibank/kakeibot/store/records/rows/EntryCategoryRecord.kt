package com.yossibank.kakeibot.store.records.rows

import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.Insert
import androidx.room.PrimaryKey
import androidx.room.Query
import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.records.protocols.ArchivableRecord
import com.yossibank.kakeibot.store.records.protocols.storedInstant
import com.yossibank.kakeibot.store.records.protocols.storedValue
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.records.values.fromDatabaseValue

@Entity(
    tableName = "category",
    foreignKeys = [
        ForeignKey(
            entity = IconRecord::class,
            parentColumns = ["id"],
            childColumns = ["icon_id"],
        ),
        ForeignKey(
            entity = WalletRecord::class,
            parentColumns = ["id"],
            childColumns = ["wallet_id"],
        ),
    ],
    indices = [
        Index(
            value = ["wallet_id"],
            name = "category_wallet_id",
        ),
    ],
)
data class EntryCategoryRecord(
    @PrimaryKey override val id: String,
    val kind: String,
    val name: String,
    @ColumnInfo(name = "icon_id") val iconId: String,
    @ColumnInfo(name = "sort_order") override val sortOrder: Int,
    @ColumnInfo(name = "archived_at") override val archivedAt: String?,
    @ColumnInfo(name = "created_at") val createdAt: String,
    @ColumnInfo(name = "updated_at") override val updatedAt: String,
    @ColumnInfo(name = "wallet_id") val walletId: String?,
) : ArchivableRecord

@Dao
interface EntryCategoryRecordDao {
    @Insert
    suspend fun insert(record: EntryCategoryRecord)

    @Query("SELECT * FROM category WHERE id = :id")
    suspend fun find(id: String): EntryCategoryRecord?

    @Query("SELECT * FROM category ORDER BY id")
    suspend fun all(): List<EntryCategoryRecord>

    @Query("DELETE FROM category")
    suspend fun deleteAll()

    @Query("SELECT * FROM category WHERE wallet_id IS NULL")
    suspend fun withoutWallet(): List<EntryCategoryRecord>

    @Query("SELECT COUNT(*) FROM category WHERE wallet_id IS NULL")
    suspend fun countWithoutWallet(): Int

    @Query("SELECT EXISTS (SELECT 1 FROM category WHERE id = :id)")
    suspend fun exists(id: String): Boolean

    @Query("SELECT MAX(sort_order) FROM category WHERE kind = :kind")
    suspend fun maxSortOrder(kind: String): Int?

    @Query("SELECT MAX(sort_order) FROM category WHERE kind = :kind AND wallet_id = :walletId")
    suspend fun maxSortOrder(
        kind: String,
        walletId: String,
    ): Int?

    @Query(
        """
        SELECT id FROM category
        WHERE wallet_id = :walletId AND kind = :kind AND name = :name
        ORDER BY archived_at IS NOT NULL, sort_order
        LIMIT 1
        """,
    )
    suspend fun firstId(
        walletId: String,
        kind: String,
        name: String,
    ): String?
}

fun EntryCategory.record(): EntryCategoryRecord = EntryCategoryRecord(
    id = id.databaseValue,
    kind = kind.rawValue,
    name = name,
    iconId = iconId.databaseValue,
    sortOrder = sortOrder,
    archivedAt = archivedAt?.storedValue,
    createdAt = createdAt.storedValue,
    updatedAt = updatedAt.storedValue,
    walletId = walletId?.databaseValue,
)

fun EntryCategoryRecord.entryCategory(): EntryCategory? {
    val id = Identifier.fromDatabaseValue<EntryCategory>(id) ?: return null
    val kind = EntryCategory.Kind.of(kind) ?: return null
    val iconId = Identifier.fromDatabaseValue<Icon>(iconId) ?: return null
    val archivedAt = archivedAt?.let { storedInstant(it) ?: return null }
    val walletId = walletId?.let { Identifier.fromDatabaseValue<Wallet>(it) ?: return null }
    val createdAt = storedInstant(createdAt) ?: return null
    val updatedAt = storedInstant(updatedAt) ?: return null

    return EntryCategory(
        id = id,
        kind = kind,
        name = name,
        iconId = iconId,
        sortOrder = sortOrder,
        archivedAt = archivedAt,
        walletId = walletId,
        createdAt = createdAt,
        updatedAt = updatedAt,
    )
}

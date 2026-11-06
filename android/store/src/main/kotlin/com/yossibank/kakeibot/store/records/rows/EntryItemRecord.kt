package com.yossibank.kakeibot.store.records.rows

import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.Insert
import androidx.room.PrimaryKey
import androidx.room.Query
import androidx.room.Upsert
import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryItem
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.records.protocols.storedInstant
import com.yossibank.kakeibot.store.records.protocols.storedValue
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.records.values.fromDatabaseValue

@Entity(
    tableName = "entry_item",
    foreignKeys = [
        ForeignKey(
            entity = EntryRecord::class,
            parentColumns = ["id"],
            childColumns = ["entry_id"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [
        Index(
            value = ["entry_id"],
            name = "entry_item_entry_id",
        ),
    ],
)
data class EntryItemRecord(
    @PrimaryKey val id: String,
    @ColumnInfo(name = "entry_id") val entryId: String,
    val name: String,
    val quantity: Int,
    val amount: Int,
    @ColumnInfo(name = "sort_order") val sortOrder: Int,
    @ColumnInfo(name = "created_at") val createdAt: String,
    @ColumnInfo(name = "updated_at") val updatedAt: String,
    @ColumnInfo(name = "tax_rate") val taxRate: Int?,
)

@Dao
interface EntryItemRecordDao {
    @Insert
    suspend fun insert(record: EntryItemRecord)

    @Query("SELECT * FROM entry_item ORDER BY id")
    suspend fun all(): List<EntryItemRecord>

    @Query("DELETE FROM entry_item")
    suspend fun deleteAll()

    @Upsert
    suspend fun save(record: EntryItemRecord)

    @Query("SELECT * FROM entry_item WHERE entry_id = :entryId ORDER BY sort_order, created_at")
    suspend fun ofEntry(entryId: String): List<EntryItemRecord>

    @Query("SELECT * FROM entry_item WHERE entry_id IN (:entryIds) ORDER BY entry_id, sort_order")
    suspend fun ofEntries(entryIds: List<String>): List<EntryItemRecord>

    @Query("DELETE FROM entry_item WHERE id IN (:ids)")
    suspend fun deleteIds(ids: List<String>)

    @Query("DELETE FROM entry_item WHERE entry_id IN (:entryIds) AND id NOT IN (:keptIds)")
    suspend fun deleteOfEntries(
        entryIds: List<String>,
        keptIds: List<String>,
    )

    @Query("UPDATE entry_item SET updated_at = :updatedAt WHERE entry_id IN (:entryIds)")
    suspend fun touch(
        entryIds: List<String>,
        updatedAt: String,
    )

    @Query(
        """
        SELECT name FROM entry_item
        WHERE amount > 0
        GROUP BY name
        ORDER BY MAX(updated_at) DESC
        LIMIT :limit
        """,
    )
    suspend fun recentNames(limit: Int): List<String>
}

fun EntryItem.record(): EntryItemRecord = EntryItemRecord(
    id = id.databaseValue,
    entryId = entryId.databaseValue,
    name = name,
    quantity = quantity,
    amount = amount,
    sortOrder = sortOrder,
    createdAt = createdAt.storedValue,
    updatedAt = updatedAt.storedValue,
    taxRate = taxRate?.rawValue,
)

fun EntryItemRecord.entryItem(): EntryItem? {
    val id = Identifier.fromDatabaseValue<EntryItem>(id) ?: return null
    val entryId = Identifier.fromDatabaseValue<Entry>(entryId) ?: return null
    val taxRate = taxRate?.let { AmountCalculator.TaxRate.of(it) ?: return null }
    val createdAt = storedInstant(createdAt) ?: return null
    val updatedAt = storedInstant(updatedAt) ?: return null

    return EntryItem(
        id = id,
        entryId = entryId,
        name = name,
        quantity = quantity,
        amount = amount,
        taxRate = taxRate,
        sortOrder = sortOrder,
        createdAt = createdAt,
        updatedAt = updatedAt,
    )
}

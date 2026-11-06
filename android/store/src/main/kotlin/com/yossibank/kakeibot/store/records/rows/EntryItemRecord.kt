package com.yossibank.kakeibot.store.records.rows

import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.Insert
import androidx.room.PrimaryKey
import androidx.room.Query
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

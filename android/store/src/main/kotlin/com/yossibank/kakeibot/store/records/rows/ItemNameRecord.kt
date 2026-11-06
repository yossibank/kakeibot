package com.yossibank.kakeibot.store.records.rows

import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Entity
import androidx.room.Index
import androidx.room.Insert
import androidx.room.PrimaryKey
import androidx.room.Query
import com.yossibank.kakeibot.core.concepts.receipt.ItemName
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.records.protocols.storedInstant
import com.yossibank.kakeibot.store.records.protocols.storedValue
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.records.values.fromDatabaseValue

@Entity(
    tableName = "item_name",
    indices = [
        Index(
            value = ["store", "raw"],
            unique = true,
        ),
    ],
)
data class ItemNameRecord(
    @PrimaryKey val id: String,
    val store: String,
    val raw: String,
    val name: String,
    @ColumnInfo(name = "created_at") val createdAt: String,
    @ColumnInfo(name = "updated_at") val updatedAt: String,
)

@Dao
interface ItemNameRecordDao {
    @Insert
    suspend fun insert(record: ItemNameRecord)

    @Query("SELECT * FROM item_name ORDER BY id")
    suspend fun all(): List<ItemNameRecord>

    @Query("DELETE FROM item_name")
    suspend fun deleteAll()
}

fun ItemName.record(): ItemNameRecord = ItemNameRecord(
    id = id.databaseValue,
    store = store,
    raw = raw,
    name = name,
    createdAt = createdAt.storedValue,
    updatedAt = updatedAt.storedValue,
)

fun ItemNameRecord.itemName(): ItemName? {
    val id = Identifier.fromDatabaseValue<ItemName>(id) ?: return null
    val createdAt = storedInstant(createdAt) ?: return null
    val updatedAt = storedInstant(updatedAt) ?: return null

    return ItemName(
        id = id,
        store = store,
        raw = raw,
        name = name,
        createdAt = createdAt,
        updatedAt = updatedAt,
    )
}

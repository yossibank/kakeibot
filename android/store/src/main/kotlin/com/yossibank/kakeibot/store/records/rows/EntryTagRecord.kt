package com.yossibank.kakeibot.store.records.rows

import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Insert
import androidx.room.PrimaryKey
import androidx.room.Query
import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.category.EntryTag
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.records.protocols.ArchivableRecord
import com.yossibank.kakeibot.store.records.protocols.storedInstant
import com.yossibank.kakeibot.store.records.protocols.storedValue
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.records.values.fromDatabaseValue

@Entity(
    tableName = "tag",
    foreignKeys = [
        ForeignKey(
            entity = EntryCategoryRecord::class,
            parentColumns = ["id"],
            childColumns = ["category_id"],
        ),
    ],
)
data class EntryTagRecord(
    @PrimaryKey override val id: String,
    @ColumnInfo(name = "category_id") val categoryId: String,
    val name: String,
    @ColumnInfo(name = "sort_order") override val sortOrder: Int,
    @ColumnInfo(name = "archived_at") override val archivedAt: String?,
    @ColumnInfo(name = "created_at") val createdAt: String,
    @ColumnInfo(name = "updated_at") override val updatedAt: String,
) : ArchivableRecord

@Dao
interface EntryTagRecordDao {
    @Insert
    suspend fun insert(record: EntryTagRecord)

    @Query("SELECT * FROM tag ORDER BY id")
    suspend fun all(): List<EntryTagRecord>
}

fun EntryTag.record(): EntryTagRecord = EntryTagRecord(
    id = id.databaseValue,
    categoryId = categoryId.databaseValue,
    name = name,
    sortOrder = sortOrder,
    archivedAt = archivedAt?.storedValue,
    createdAt = createdAt.storedValue,
    updatedAt = updatedAt.storedValue,
)

fun EntryTagRecord.entryTag(): EntryTag? {
    val id = Identifier.fromDatabaseValue<EntryTag>(id) ?: return null
    val categoryId = Identifier.fromDatabaseValue<EntryCategory>(categoryId) ?: return null
    val archivedAt = archivedAt?.let { storedInstant(it) ?: return null }
    val createdAt = storedInstant(createdAt) ?: return null
    val updatedAt = storedInstant(updatedAt) ?: return null

    return EntryTag(
        id = id,
        categoryId = categoryId,
        name = name,
        sortOrder = sortOrder,
        archivedAt = archivedAt,
        createdAt = createdAt,
        updatedAt = updatedAt,
    )
}

package com.yossibank.kakeibot.store.records.rows

import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Insert
import androidx.room.PrimaryKey
import androidx.room.Query
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.icon.ShelfIcon
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.records.protocols.ArchivableRecord
import com.yossibank.kakeibot.store.records.protocols.storedInstant
import com.yossibank.kakeibot.store.records.protocols.storedValue
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.records.values.fromDatabaseValue

@Entity(
    tableName = "shelf_icon",
    foreignKeys = [
        ForeignKey(
            entity = IconRecord::class,
            parentColumns = ["id"],
            childColumns = ["icon_id"],
        ),
    ],
)
data class ShelfIconRecord(
    @PrimaryKey override val id: String,
    @ColumnInfo(name = "icon_id") val iconId: String,
    @ColumnInfo(name = "sort_order") override val sortOrder: Int,
    @ColumnInfo(name = "archived_at") override val archivedAt: String?,
    @ColumnInfo(name = "created_at") val createdAt: String,
    @ColumnInfo(name = "updated_at") override val updatedAt: String,
) : ArchivableRecord

@Dao
interface ShelfIconRecordDao {
    @Insert
    suspend fun insert(record: ShelfIconRecord)

    @Query("SELECT * FROM shelf_icon WHERE id = :id")
    suspend fun find(id: String): ShelfIconRecord?

    @Query("SELECT * FROM shelf_icon ORDER BY id")
    suspend fun all(): List<ShelfIconRecord>

    @Query("DELETE FROM shelf_icon")
    suspend fun deleteAll()

    @Query("SELECT COUNT(*) FROM shelf_icon")
    suspend fun count(): Int
}

fun ShelfIcon.record(): ShelfIconRecord = ShelfIconRecord(
    id = id.databaseValue,
    iconId = iconId.databaseValue,
    sortOrder = sortOrder,
    archivedAt = archivedAt?.storedValue,
    createdAt = createdAt.storedValue,
    updatedAt = updatedAt.storedValue,
)

fun ShelfIconRecord.shelfIcon(): ShelfIcon? {
    val id = Identifier.fromDatabaseValue<ShelfIcon>(id) ?: return null
    val iconId = Identifier.fromDatabaseValue<Icon>(iconId) ?: return null
    val archivedAt = archivedAt?.let { storedInstant(it) ?: return null }
    val createdAt = storedInstant(createdAt) ?: return null
    val updatedAt = storedInstant(updatedAt) ?: return null

    return ShelfIcon(
        id = id,
        iconId = iconId,
        sortOrder = sortOrder,
        archivedAt = archivedAt,
        createdAt = createdAt,
        updatedAt = updatedAt,
    )
}

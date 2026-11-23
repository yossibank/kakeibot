package com.yossibank.kakeibot.store.records.rows

import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.Query
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.records.protocols.TableBinding
import com.yossibank.kakeibot.store.records.protocols.UpdatableDao
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.protocols.storedInstant
import com.yossibank.kakeibot.store.records.protocols.storedValue
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.records.values.fromDatabaseValue

@Entity(tableName = "icon")
data class IconRecord(
    @PrimaryKey val id: String,
    val emoji: String?,
    val text: String?,
    val glyph: String?,
    val color: String,
    @ColumnInfo(name = "created_at") val createdAt: String,
    @ColumnInfo(name = "updated_at") val updatedAt: String,
)

@Dao
interface IconRecordDao : UpdatableDao<IconRecord> {
    @Query("SELECT * FROM icon WHERE id = :id")
    suspend fun find(id: String): IconRecord?

    @Query("SELECT * FROM icon ORDER BY id")
    suspend fun all(): List<IconRecord>

    @Query("DELETE FROM icon")
    suspend fun deleteAll()

    @Query("SELECT * FROM icon WHERE id IN (:ids)")
    suspend fun withIds(ids: List<String>): List<IconRecord>

    @Query("DELETE FROM icon WHERE id IN (:ids)")
    suspend fun deleteIds(ids: List<String>)
}

fun Icon.record(): IconRecord = IconRecord(
    id = id.databaseValue,
    emoji = emoji,
    text = text,
    glyph = glyph?.rawValue,
    color = color,
    createdAt = createdAt.storedValue,
    updatedAt = updatedAt.storedValue,
)

fun IconRecord.icon(): Icon? {
    val id = Identifier.fromDatabaseValue<Icon>(id) ?: return null
    val createdAt = storedInstant(createdAt) ?: return null
    val updatedAt = storedInstant(updatedAt) ?: return null

    return Icon(
        id = id,
        emoji = emoji,
        text = text,
        glyph = glyph?.let(Icon.Glyph::known),
        color = color,
        createdAt = createdAt,
        updatedAt = updatedAt,
    )
}

internal val iconTable = TableBinding<Icon>(
    all = { iconDao().all().map { it.decoded(IconRecord::icon) } },
    insert = { iconDao().insert(it.record()) },
    deleteAll = { iconDao().deleteAll() },
)

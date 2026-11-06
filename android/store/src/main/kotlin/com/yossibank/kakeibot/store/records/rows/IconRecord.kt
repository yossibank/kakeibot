package com.yossibank.kakeibot.store.records.rows

import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Entity
import androidx.room.Insert
import androidx.room.PrimaryKey
import androidx.room.Query
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.core.shared.InstantSerializer

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
interface IconRecordDao {
    @Insert
    suspend fun insert(record: IconRecord)

    @Query("SELECT * FROM icon WHERE id = :id")
    suspend fun find(id: String): IconRecord?
}

fun Icon.record(): IconRecord = IconRecord(
    id = id.toString(),
    emoji = emoji,
    text = text,
    glyph = glyph?.rawValue,
    color = color,
    createdAt = InstantSerializer.format(createdAt),
    updatedAt = InstantSerializer.format(updatedAt),
)

fun IconRecord.icon(): Icon? {
    val id = Identifier.parse<Icon>(id) ?: return null
    val createdAt = InstantSerializer.parse(createdAt) ?: return null
    val updatedAt = InstantSerializer.parse(updatedAt) ?: return null

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

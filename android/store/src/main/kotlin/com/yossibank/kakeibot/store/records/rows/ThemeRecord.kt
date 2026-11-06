package com.yossibank.kakeibot.store.records.rows

import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Entity
import androidx.room.Insert
import androidx.room.PrimaryKey
import androidx.room.Query
import com.yossibank.kakeibot.core.concepts.theme.Theme
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.records.protocols.storedInstant
import com.yossibank.kakeibot.store.records.protocols.storedValue
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.records.values.fromDatabaseValue

@Entity(tableName = "theme")
data class ThemeRecord(
    @PrimaryKey val id: String,
    val name: String,
    val background: String,
    val surface: String,
    @ColumnInfo(name = "text_primary") val textPrimary: String,
    @ColumnInfo(name = "text_secondary") val textSecondary: String,
    val accent: String,
    val expense: String,
    val income: String,
    @ColumnInfo(name = "corner_radius") val cornerRadius: Int,
    @ColumnInfo(name = "font_id") val fontId: String,
    @ColumnInfo(name = "is_builtin") val isBuiltin: Boolean,
    @ColumnInfo(name = "created_at") val createdAt: String,
    @ColumnInfo(name = "updated_at") val updatedAt: String,
)

@Dao
interface ThemeRecordDao {
    @Insert
    suspend fun insert(record: ThemeRecord)

    @Query("SELECT * FROM theme ORDER BY id")
    suspend fun all(): List<ThemeRecord>

    @Query("DELETE FROM theme")
    suspend fun deleteAll()

    @Query("SELECT * FROM theme WHERE id = :id")
    suspend fun find(id: String): ThemeRecord?

    @Query("SELECT * FROM theme WHERE is_builtin = 0 ORDER BY created_at")
    suspend fun custom(): List<ThemeRecord>
}

fun Theme.record(): ThemeRecord = ThemeRecord(
    id = id.databaseValue,
    name = name,
    background = background,
    surface = surface,
    textPrimary = textPrimary,
    textSecondary = textSecondary,
    accent = accent,
    expense = expense,
    income = income,
    cornerRadius = cornerRadius,
    fontId = fontId,
    isBuiltin = isBuiltin,
    createdAt = createdAt.storedValue,
    updatedAt = updatedAt.storedValue,
)

fun ThemeRecord.theme(): Theme? {
    val id = Identifier.fromDatabaseValue<Theme>(id) ?: return null
    val createdAt = storedInstant(createdAt) ?: return null
    val updatedAt = storedInstant(updatedAt) ?: return null

    return Theme(
        id = id,
        name = name,
        background = background,
        surface = surface,
        textPrimary = textPrimary,
        textSecondary = textSecondary,
        accent = accent,
        expense = expense,
        income = income,
        cornerRadius = cornerRadius,
        fontId = fontId,
        isBuiltin = isBuiltin,
        createdAt = createdAt,
        updatedAt = updatedAt,
    )
}

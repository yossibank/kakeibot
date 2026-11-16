package com.yossibank.kakeibot.store.records.rows

import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Insert
import androidx.room.PrimaryKey
import androidx.room.Query
import androidx.room.Update
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

    @Query("DELETE FROM tag")
    suspend fun deleteAll()

    @Query(
        """
        SELECT * FROM tag
        WHERE archived_at IS NULL AND category_id IN (SELECT id FROM category WHERE wallet_id IS NULL)
        ORDER BY sort_order
        """,
    )
    suspend fun unarchivedWithoutWallet(): List<EntryTagRecord>

    @Query(
        """
        SELECT * FROM tag
        WHERE category_id IN (SELECT id FROM category WHERE wallet_id IS NULL)
        ORDER BY sort_order
        """,
    )
    suspend fun withoutWalletInOrder(): List<EntryTagRecord>

    @Query(
        """
        SELECT * FROM tag
        WHERE category_id IN (SELECT id FROM category WHERE wallet_id IS NOT NULL)
        ORDER BY sort_order
        """,
    )
    suspend fun ofWalletsInOrder(): List<EntryTagRecord>

    @Query("SELECT * FROM tag WHERE id = :id")
    suspend fun find(id: String): EntryTagRecord?

    @Update
    suspend fun update(record: EntryTagRecord)

    @Query("SELECT * FROM tag WHERE category_id = :categoryId")
    suspend fun ofCategory(categoryId: String): List<EntryTagRecord>

    @Query("SELECT * FROM tag WHERE category_id IN (:categoryIds)")
    suspend fun ofCategories(categoryIds: List<String>): List<EntryTagRecord>

    @Query("DELETE FROM tag WHERE category_id IN (:categoryIds)")
    suspend fun deleteOfCategories(categoryIds: List<String>)

    @Query(
        """
        SELECT tag.id FROM tag
        JOIN tag AS original ON original.name = tag.name
        WHERE original.id = :tagId AND tag.category_id = :categoryId
        ORDER BY tag.archived_at IS NOT NULL, tag.sort_order
        LIMIT 1
        """,
    )
    suspend fun firstId(
        tagId: String,
        categoryId: String,
    ): String?
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

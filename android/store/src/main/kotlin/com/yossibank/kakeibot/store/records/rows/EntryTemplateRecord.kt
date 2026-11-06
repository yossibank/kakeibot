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
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplate
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.records.protocols.SortableRecord
import com.yossibank.kakeibot.store.records.protocols.storedInstant
import com.yossibank.kakeibot.store.records.protocols.storedValue
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.records.values.fromDatabaseValue

@Entity(
    tableName = "template",
    foreignKeys = [
        ForeignKey(
            entity = EntryCategoryRecord::class,
            parentColumns = ["id"],
            childColumns = ["category_id"],
        ),
        ForeignKey(
            entity = WalletRecord::class,
            parentColumns = ["id"],
            childColumns = ["wallet_id"],
        ),
        ForeignKey(
            entity = EntryTagRecord::class,
            parentColumns = ["id"],
            childColumns = ["tag_id"],
        ),
    ],
)
data class EntryTemplateRecord(
    @PrimaryKey override val id: String,
    val name: String,
    val type: String,
    val amount: Int?,
    @ColumnInfo(name = "category_id") val categoryId: String,
    @ColumnInfo(name = "wallet_id") val walletId: String,
    val memo: String?,
    @ColumnInfo(name = "sort_order") override val sortOrder: Int,
    @ColumnInfo(name = "created_at") val createdAt: String,
    @ColumnInfo(name = "updated_at") override val updatedAt: String,
    @ColumnInfo(name = "tag_id") val tagId: String?,
    @ColumnInfo(name = "archived_at") val archivedAt: String?,
    @ColumnInfo(name = "bill_shift", defaultValue = "0") val billShift: Int,
) : SortableRecord

@Dao
interface EntryTemplateRecordDao {
    @Insert
    suspend fun insert(record: EntryTemplateRecord)

    @Query("SELECT * FROM template ORDER BY id")
    suspend fun all(): List<EntryTemplateRecord>

    @Query("DELETE FROM template")
    suspend fun deleteAll()

    @Query("SELECT COUNT(*) FROM template")
    suspend fun count(): Int
}

fun EntryTemplate.record(): EntryTemplateRecord = EntryTemplateRecord(
    id = id.databaseValue,
    name = name,
    type = type.rawValue,
    amount = amount,
    categoryId = categoryId.databaseValue,
    walletId = walletId.databaseValue,
    memo = memo,
    sortOrder = sortOrder,
    createdAt = createdAt.storedValue,
    updatedAt = updatedAt.storedValue,
    tagId = tagId?.databaseValue,
    archivedAt = archivedAt?.storedValue,
    billShift = billShift,
)

fun EntryTemplateRecord.entryTemplate(): EntryTemplate? {
    val id = Identifier.fromDatabaseValue<EntryTemplate>(id) ?: return null
    val type = Entry.Kind.of(type) ?: return null
    val categoryId = Identifier.fromDatabaseValue<EntryCategory>(categoryId) ?: return null
    val tagId = tagId?.let { Identifier.fromDatabaseValue<EntryTag>(it) ?: return null }
    val walletId = Identifier.fromDatabaseValue<Wallet>(walletId) ?: return null
    val archivedAt = archivedAt?.let { storedInstant(it) ?: return null }
    val createdAt = storedInstant(createdAt) ?: return null
    val updatedAt = storedInstant(updatedAt) ?: return null

    return EntryTemplate(
        id = id,
        name = name,
        type = type,
        amount = amount,
        categoryId = categoryId,
        tagId = tagId,
        walletId = walletId,
        memo = memo,
        billShift = billShift,
        sortOrder = sortOrder,
        archivedAt = archivedAt,
        createdAt = createdAt,
        updatedAt = updatedAt,
    )
}

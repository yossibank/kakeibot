package com.yossibank.kakeibot.store.records.rows

import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.Insert
import androidx.room.PrimaryKey
import androidx.room.Query
import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.category.EntryTag
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplate
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.records.protocols.storedInstant
import com.yossibank.kakeibot.store.records.protocols.storedValue
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.records.values.fromDatabaseValue

@Entity(
    tableName = "entry",
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
            entity = WalletRecord::class,
            parentColumns = ["id"],
            childColumns = ["to_wallet_id"],
        ),
        ForeignKey(
            entity = RecurringRecord::class,
            parentColumns = ["id"],
            childColumns = ["recurring_id"],
        ),
        ForeignKey(
            entity = EntryTagRecord::class,
            parentColumns = ["id"],
            childColumns = ["tag_id"],
        ),
        ForeignKey(
            entity = EntryTemplateRecord::class,
            parentColumns = ["id"],
            childColumns = ["template_id"],
            onDelete = ForeignKey.SET_NULL,
        ),
        ForeignKey(
            entity = EntryRecord::class,
            parentColumns = ["id"],
            childColumns = ["transfer_id"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [
        Index(
            value = ["recurring_id", "recurring_date"],
            unique = true,
        ),
        Index(
            value = ["transfer_id"],
            name = "entry_transfer",
            unique = true,
        ),
        Index(
            value = ["date"],
            name = "entry_date",
        ),
        Index(
            value = ["wallet_id", "date"],
            name = "entry_wallet_id_date",
        ),
        Index(
            value = ["to_wallet_id"],
            name = "entry_to_wallet_id",
        ),
        Index(
            value = ["category_id"],
            name = "entry_category_id",
        ),
    ],
)
data class EntryRecord(
    @PrimaryKey val id: String,
    val type: String,
    val amount: Int,
    @ColumnInfo(name = "category_id") val categoryId: String?,
    @ColumnInfo(name = "wallet_id") val walletId: String,
    @ColumnInfo(name = "to_wallet_id") val toWalletId: String?,
    val memo: String?,
    val date: String,
    @ColumnInfo(name = "recurring_id") val recurringId: String?,
    @ColumnInfo(name = "recurring_date") val recurringDate: String?,
    @ColumnInfo(name = "created_at") val createdAt: String,
    @ColumnInfo(name = "updated_at") val updatedAt: String,
    @ColumnInfo(name = "tag_id") val tagId: String?,
    @ColumnInfo(name = "template_id") val templateId: String?,
    @ColumnInfo(name = "bill_month") val billMonth: String?,
    @ColumnInfo(name = "transfer_id") val transferId: String?,
    @ColumnInfo(name = "tax_included", defaultValue = "0") val taxIncluded: Boolean,
)

@Dao
interface EntryRecordDao {
    @Insert
    suspend fun insert(record: EntryRecord)

    @Query("SELECT * FROM entry WHERE id = :id")
    suspend fun find(id: String): EntryRecord?

    @Query("SELECT * FROM entry ORDER BY id")
    suspend fun all(): List<EntryRecord>

    @Query("DELETE FROM entry")
    suspend fun deleteAll()

    @Query("SELECT COUNT(*) FROM entry")
    suspend fun count(): Int
}

fun Entry.record(): EntryRecord = EntryRecord(
    id = id.databaseValue,
    type = type.rawValue,
    amount = amount,
    categoryId = categoryId?.databaseValue,
    walletId = walletId.databaseValue,
    toWalletId = toWalletId?.databaseValue,
    memo = memo,
    date = date.databaseValue,
    recurringId = recurringId?.databaseValue,
    recurringDate = recurringDate?.databaseValue,
    createdAt = createdAt.storedValue,
    updatedAt = updatedAt.storedValue,
    tagId = tagId?.databaseValue,
    templateId = templateId?.databaseValue,
    billMonth = billMonth?.databaseValue,
    transferId = transferId?.databaseValue,
    taxIncluded = taxIncluded,
)

fun EntryRecord.entry(): Entry? {
    val id = Identifier.fromDatabaseValue<Entry>(id) ?: return null
    val type = Entry.Kind.of(type) ?: return null
    val date = LocalDate.fromDatabaseValue(date) ?: return null
    val categoryId = categoryId?.let { Identifier.fromDatabaseValue<EntryCategory>(it) ?: return null }
    val tagId = tagId?.let { Identifier.fromDatabaseValue<EntryTag>(it) ?: return null }
    val templateId = templateId?.let { Identifier.fromDatabaseValue<EntryTemplate>(it) ?: return null }
    val walletId = Identifier.fromDatabaseValue<Wallet>(walletId) ?: return null
    val toWalletId = toWalletId?.let { Identifier.fromDatabaseValue<Wallet>(it) ?: return null }
    val recurringId = recurringId?.let { Identifier.fromDatabaseValue<Recurring>(it) ?: return null }
    val recurringDate = recurringDate?.let { LocalDate.fromDatabaseValue(it) ?: return null }
    val billMonth = billMonth?.let { YearMonth.fromDatabaseValue(it) ?: return null }
    val transferId = transferId?.let { Identifier.fromDatabaseValue<Entry>(it) ?: return null }
    val createdAt = storedInstant(createdAt) ?: return null
    val updatedAt = storedInstant(updatedAt) ?: return null

    return Entry(
        id = id,
        type = type,
        amount = amount,
        date = date,
        categoryId = categoryId,
        tagId = tagId,
        templateId = templateId,
        walletId = walletId,
        toWalletId = toWalletId,
        memo = memo,
        recurringId = recurringId,
        recurringDate = recurringDate,
        billMonth = billMonth,
        transferId = transferId,
        taxIncluded = taxIncluded,
        createdAt = createdAt,
        updatedAt = updatedAt,
    )
}

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
import com.yossibank.kakeibot.core.concepts.date.HolidayShift
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.records.protocols.SortableRecord
import com.yossibank.kakeibot.store.records.protocols.storedInstant
import com.yossibank.kakeibot.store.records.protocols.storedValue
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.records.values.fromDatabaseValue

@Entity(
    tableName = "recurring",
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
    ],
)
data class RecurringRecord(
    @PrimaryKey override val id: String,
    val type: String,
    val amount: Int,
    @ColumnInfo(name = "category_id") val categoryId: String?,
    @ColumnInfo(name = "wallet_id") val walletId: String,
    @ColumnInfo(name = "to_wallet_id") val toWalletId: String?,
    val memo: String?,
    val frequency: String,
    val month: Int?,
    val day: Int,
    @ColumnInfo(name = "holiday_shift", defaultValue = "'none'") val holidayShift: String,
    @ColumnInfo(name = "closing_day") val closingDay: Int?,
    @ColumnInfo(name = "start_date") val startDate: String,
    @ColumnInfo(name = "end_date") val endDate: String?,
    @ColumnInfo(name = "remind_days_before") val remindDaysBefore: Int?,
    @ColumnInfo(name = "generated_until") val generatedUntil: String?,
    @ColumnInfo(name = "sort_order", defaultValue = "0") override val sortOrder: Int,
    @ColumnInfo(name = "archived_at") val archivedAt: String?,
    @ColumnInfo(name = "created_at") val createdAt: String,
    @ColumnInfo(name = "updated_at") override val updatedAt: String,
    val fee: Int?,
    @ColumnInfo(name = "bill_shift", defaultValue = "0") val billShift: Int,
    @ColumnInfo(name = "final_amount") val finalAmount: Int?,
) : SortableRecord

@Dao
interface RecurringRecordDao {
    @Insert
    suspend fun insert(record: RecurringRecord)

    @Query("SELECT * FROM recurring ORDER BY id")
    suspend fun all(): List<RecurringRecord>

    @Query("DELETE FROM recurring")
    suspend fun deleteAll()

    @Query("SELECT * FROM recurring ORDER BY sort_order, created_at")
    suspend fun inOrder(): List<RecurringRecord>

    @Query("SELECT * FROM recurring WHERE archived_at IS NULL ORDER BY sort_order, created_at")
    suspend fun unarchivedInOrder(): List<RecurringRecord>

    @Query(
        """
        SELECT * FROM recurring
        WHERE archived_at IS NULL AND type = 'transfer' AND closing_day IS NOT NULL
        ORDER BY sort_order, created_at
        """,
    )
    suspend fun cardBills(): List<RecurringRecord>

    @Query("SELECT * FROM recurring WHERE id = :id")
    suspend fun find(id: String): RecurringRecord?

    @Update
    suspend fun update(record: RecurringRecord)

    @Query("SELECT MAX(sort_order) FROM recurring")
    suspend fun maxSortOrder(): Int?

    @Query("SELECT * FROM recurring WHERE wallet_id = :walletId OR to_wallet_id = :walletId")
    suspend fun ofWallet(walletId: String): List<RecurringRecord>

    @Query("SELECT COUNT(*) FROM recurring WHERE wallet_id = :walletId OR to_wallet_id = :walletId")
    suspend fun countOfWallet(walletId: String): Int

    @Query("SELECT * FROM recurring WHERE category_id = :categoryId")
    suspend fun ofCategory(categoryId: String): List<RecurringRecord>

    @Query("DELETE FROM recurring WHERE id IN (:ids)")
    suspend fun deleteIds(ids: List<String>)

    @Query("SELECT * FROM recurring WHERE closing_day IS NOT NULL AND to_wallet_id IN (:cards)")
    suspend fun billing(cards: List<String>): List<RecurringRecord>

    @Query(
        """
        SELECT * FROM recurring
        WHERE archived_at IS NULL AND type = 'transfer' AND closing_day IS NOT NULL AND to_wallet_id = :walletId
        ORDER BY sort_order, created_at
        LIMIT 1
        """,
    )
    suspend fun cardBill(walletId: String): RecurringRecord?

    @Query("UPDATE recurring SET generated_until = :date WHERE id = :id")
    suspend fun setGeneratedUntil(
        id: String,
        date: String,
    )
}

fun Recurring.record(): RecurringRecord = RecurringRecord(
    id = id.databaseValue,
    type = type.rawValue,
    amount = amount,
    categoryId = categoryId?.databaseValue,
    walletId = walletId.databaseValue,
    toWalletId = toWalletId?.databaseValue,
    memo = memo,
    frequency = frequency.rawValue,
    month = month,
    day = day,
    holidayShift = holidayShift.rawValue,
    closingDay = closingDay,
    startDate = startDate.databaseValue,
    endDate = endDate?.databaseValue,
    remindDaysBefore = remindDaysBefore,
    generatedUntil = generatedUntil?.databaseValue,
    sortOrder = sortOrder,
    archivedAt = archivedAt?.storedValue,
    createdAt = createdAt.storedValue,
    updatedAt = updatedAt.storedValue,
    fee = fee,
    billShift = billShift,
    finalAmount = finalAmount,
)

fun RecurringRecord.recurring(): Recurring? {
    val id = Identifier.fromDatabaseValue<Recurring>(id) ?: return null
    val type = Entry.Kind.of(type) ?: return null
    val categoryId = categoryId?.let { Identifier.fromDatabaseValue<EntryCategory>(it) ?: return null }
    val walletId = Identifier.fromDatabaseValue<Wallet>(walletId) ?: return null
    val toWalletId = toWalletId?.let { Identifier.fromDatabaseValue<Wallet>(it) ?: return null }
    val frequency = Recurring.Frequency.of(frequency) ?: return null
    val holidayShift = HolidayShift.of(holidayShift) ?: return null
    val startDate = LocalDate.fromDatabaseValue(startDate) ?: return null
    val endDate = endDate?.let { LocalDate.fromDatabaseValue(it) ?: return null }
    val generatedUntil = generatedUntil?.let { LocalDate.fromDatabaseValue(it) ?: return null }
    val archivedAt = archivedAt?.let { storedInstant(it) ?: return null }
    val createdAt = storedInstant(createdAt) ?: return null
    val updatedAt = storedInstant(updatedAt) ?: return null

    return Recurring(
        id = id,
        type = type,
        amount = amount,
        categoryId = categoryId,
        walletId = walletId,
        toWalletId = toWalletId,
        memo = memo,
        frequency = frequency,
        month = month,
        day = day,
        holidayShift = holidayShift,
        closingDay = closingDay,
        fee = fee,
        finalAmount = finalAmount,
        billShift = billShift,
        startDate = startDate,
        endDate = endDate,
        remindDaysBefore = remindDaysBefore,
        generatedUntil = generatedUntil,
        sortOrder = sortOrder,
        archivedAt = archivedAt,
        createdAt = createdAt,
        updatedAt = updatedAt,
    )
}

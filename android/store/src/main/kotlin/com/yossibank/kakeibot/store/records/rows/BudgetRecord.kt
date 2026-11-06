package com.yossibank.kakeibot.store.records.rows

import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.Insert
import androidx.room.PrimaryKey
import androidx.room.Query
import com.yossibank.kakeibot.core.concepts.budget.Budget
import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.records.values.fromDatabaseValue

@Entity(
    tableName = "budget",
    foreignKeys = [
        ForeignKey(
            entity = EntryCategoryRecord::class,
            parentColumns = ["id"],
            childColumns = ["category_id"],
        ),
    ],
    indices = [
        Index(
            value = ["category_id", "from_month"],
            unique = true,
        ),
    ],
)
data class BudgetRecord(
    @PrimaryKey val id: String,
    @ColumnInfo(name = "category_id") val categoryId: String?,
    @ColumnInfo(name = "from_month") val fromMonth: String,
    val amount: Int?,
)

@Dao
interface BudgetRecordDao {
    @Insert
    suspend fun insert(record: BudgetRecord)

    @Query("SELECT * FROM budget ORDER BY id")
    suspend fun all(): List<BudgetRecord>

    @Query("DELETE FROM budget")
    suspend fun deleteAll()

    @Query("SELECT * FROM budget ORDER BY from_month")
    suspend fun inMonthOrder(): List<BudgetRecord>
}

fun Budget.record(): BudgetRecord = BudgetRecord(
    id = id.databaseValue,
    categoryId = categoryId?.databaseValue,
    fromMonth = fromMonth.databaseValue,
    amount = amount,
)

fun BudgetRecord.budget(): Budget? {
    val id = Identifier.fromDatabaseValue<Budget>(id) ?: return null
    val categoryId = categoryId?.let { Identifier.fromDatabaseValue<EntryCategory>(it) ?: return null }
    val fromMonth = YearMonth.fromDatabaseValue(fromMonth) ?: return null

    return Budget(
        id = id,
        categoryId = categoryId,
        fromMonth = fromMonth,
        amount = amount,
    )
}

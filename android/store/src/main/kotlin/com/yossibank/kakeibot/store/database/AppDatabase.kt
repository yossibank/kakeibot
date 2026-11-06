package com.yossibank.kakeibot.store.database

import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.deferredTransaction
import androidx.room.immediateTransaction
import androidx.room.useReaderConnection
import androidx.room.useWriterConnection
import androidx.sqlite.driver.bundled.BundledSQLiteDriver
import com.yossibank.kakeibot.store.records.rows.AdjustmentRecord
import com.yossibank.kakeibot.store.records.rows.AdjustmentRecordDao
import com.yossibank.kakeibot.store.records.rows.BudgetRecord
import com.yossibank.kakeibot.store.records.rows.BudgetRecordDao
import com.yossibank.kakeibot.store.records.rows.CalendarStampRecord
import com.yossibank.kakeibot.store.records.rows.CalendarStampRecordDao
import com.yossibank.kakeibot.store.records.rows.EntryCategoryRecord
import com.yossibank.kakeibot.store.records.rows.EntryCategoryRecordDao
import com.yossibank.kakeibot.store.records.rows.EntryItemRecord
import com.yossibank.kakeibot.store.records.rows.EntryItemRecordDao
import com.yossibank.kakeibot.store.records.rows.EntryRecord
import com.yossibank.kakeibot.store.records.rows.EntryRecordDao
import com.yossibank.kakeibot.store.records.rows.EntryTagRecord
import com.yossibank.kakeibot.store.records.rows.EntryTagRecordDao
import com.yossibank.kakeibot.store.records.rows.EntryTemplateRecord
import com.yossibank.kakeibot.store.records.rows.EntryTemplateRecordDao
import com.yossibank.kakeibot.store.records.rows.IconRecord
import com.yossibank.kakeibot.store.records.rows.IconRecordDao
import com.yossibank.kakeibot.store.records.rows.ItemNameRecord
import com.yossibank.kakeibot.store.records.rows.ItemNameRecordDao
import com.yossibank.kakeibot.store.records.rows.NoSpendDayRecord
import com.yossibank.kakeibot.store.records.rows.NoSpendDayRecordDao
import com.yossibank.kakeibot.store.records.rows.RecurringRecord
import com.yossibank.kakeibot.store.records.rows.RecurringRecordDao
import com.yossibank.kakeibot.store.records.rows.RewardGoalRecord
import com.yossibank.kakeibot.store.records.rows.RewardGoalRecordDao
import com.yossibank.kakeibot.store.records.rows.RewardLogRecord
import com.yossibank.kakeibot.store.records.rows.RewardLogRecordDao
import com.yossibank.kakeibot.store.records.rows.RewardRuleRecord
import com.yossibank.kakeibot.store.records.rows.RewardRuleRecordDao
import com.yossibank.kakeibot.store.records.rows.SettingRecord
import com.yossibank.kakeibot.store.records.rows.SettingRecordDao
import com.yossibank.kakeibot.store.records.rows.ShelfIconRecord
import com.yossibank.kakeibot.store.records.rows.ShelfIconRecordDao
import com.yossibank.kakeibot.store.records.rows.ThemeRecord
import com.yossibank.kakeibot.store.records.rows.ThemeRecordDao
import com.yossibank.kakeibot.store.records.rows.ValuationRecord
import com.yossibank.kakeibot.store.records.rows.ValuationRecordDao
import com.yossibank.kakeibot.store.records.rows.WalletRecord
import com.yossibank.kakeibot.store.records.rows.WalletRecordDao
import kotlinx.coroutines.Dispatchers

@Database(
    entities = [
        IconRecord::class,
        ShelfIconRecord::class,
        WalletRecord::class,
        ValuationRecord::class,
        AdjustmentRecord::class,
        EntryCategoryRecord::class,
        EntryTagRecord::class,
        RecurringRecord::class,
        EntryTemplateRecord::class,
        EntryRecord::class,
        EntryItemRecord::class,
        ItemNameRecord::class,
        BudgetRecord::class,
        RewardRuleRecord::class,
        RewardLogRecord::class,
        RewardGoalRecord::class,
        CalendarStampRecord::class,
        NoSpendDayRecord::class,
        ThemeRecord::class,
        SettingRecord::class,
    ],
    version = 1,
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun iconDao(): IconRecordDao

    abstract fun shelfIconDao(): ShelfIconRecordDao

    abstract fun walletDao(): WalletRecordDao

    abstract fun valuationDao(): ValuationRecordDao

    abstract fun adjustmentDao(): AdjustmentRecordDao

    abstract fun categoryDao(): EntryCategoryRecordDao

    abstract fun tagDao(): EntryTagRecordDao

    abstract fun recurringDao(): RecurringRecordDao

    abstract fun templateDao(): EntryTemplateRecordDao

    abstract fun entryDao(): EntryRecordDao

    abstract fun entryItemDao(): EntryItemRecordDao

    abstract fun itemNameDao(): ItemNameRecordDao

    abstract fun budgetDao(): BudgetRecordDao

    abstract fun rewardRuleDao(): RewardRuleRecordDao

    abstract fun rewardLogDao(): RewardLogRecordDao

    abstract fun rewardGoalDao(): RewardGoalRecordDao

    abstract fun calendarStampDao(): CalendarStampRecordDao

    abstract fun noSpendDayDao(): NoSpendDayRecordDao

    abstract fun themeDao(): ThemeRecordDao

    abstract fun settingDao(): SettingRecordDao

    companion object {
        fun inMemory(): AppDatabase = Room
            .inMemoryDatabaseBuilder<AppDatabase>()
            .configured()

        private fun Builder<AppDatabase>.configured(): AppDatabase = setDriver(BundledSQLiteDriver())
            .setQueryCoroutineContext(Dispatchers.IO)
            .addCallback(AppDatabaseChecks)
            .build()
    }
}

internal suspend fun <Result> AppDatabase.write(block: suspend () -> Result): Result = useWriterConnection { connection ->
    connection.immediateTransaction {
        block()
    }
}

internal suspend fun <Result> AppDatabase.read(block: suspend () -> Result): Result = useReaderConnection { connection ->
    connection.deferredTransaction {
        block()
    }
}

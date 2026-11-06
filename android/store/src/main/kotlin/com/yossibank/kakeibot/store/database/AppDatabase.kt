package com.yossibank.kakeibot.store.database

import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.sqlite.driver.bundled.BundledSQLiteDriver
import com.yossibank.kakeibot.store.records.rows.IconRecord
import com.yossibank.kakeibot.store.records.rows.IconRecordDao
import kotlinx.coroutines.Dispatchers

@Database(
    entities = [
        IconRecord::class,
    ],
    version = 1,
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun iconDao(): IconRecordDao

    companion object {
        fun inMemory(): AppDatabase = Room
            .inMemoryDatabaseBuilder<AppDatabase>()
            .setDriver(BundledSQLiteDriver())
            .setQueryCoroutineContext(Dispatchers.IO)
            .build()
    }
}


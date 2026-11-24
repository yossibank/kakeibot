package com.yossibank.kakeibot.features.support

import android.content.ContextWrapper
import androidx.room.Room
import androidx.room.RoomDatabase
import com.yossibank.kakeibot.store.database.AppDatabase
import java.time.Instant

object ModelTestDatabase {
    val now: Instant = Instant.ofEpochSecond(1_791_000_000)

    suspend fun open(): AppDatabase = AppDatabase.open(
        builder = Room
            .inMemoryDatabaseBuilder<AppDatabase>(context = ContextWrapper(null))
            .setJournalMode(RoomDatabase.JournalMode.TRUNCATE),
        now = now,
    )
}

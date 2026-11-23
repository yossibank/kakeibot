package com.yossibank.kakeibot.store.database

import android.content.Context
import androidx.room.Room
import java.time.Instant

suspend fun AppDatabase.Companion.file(
    context: Context,
    name: String = "kakeibot.sqlite",
    now: Instant,
): AppDatabase {
    val appContext = context.applicationContext
    val path = appContext.getDatabasePath(name).absolutePath

    return open(
        builder = Room.databaseBuilder<AppDatabase>(
            context = appContext,
            name = path,
        ),
        now = now,
    )
}

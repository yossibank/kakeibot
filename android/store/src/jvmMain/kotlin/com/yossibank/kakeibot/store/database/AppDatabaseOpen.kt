package com.yossibank.kakeibot.store.database

import androidx.room.Room
import java.time.Instant

fun AppDatabase.Companion.inMemory(): AppDatabase = Room
    .inMemoryDatabaseBuilder<AppDatabase>()
    .configured()

suspend fun AppDatabase.Companion.file(
    path: String,
    now: Instant = Instant.now(),
): AppDatabase = open(
    builder = Room.databaseBuilder<AppDatabase>(name = path),
    now = now,
)

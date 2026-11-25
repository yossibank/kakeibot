package com.yossibank.kakeibot.store.database

import androidx.sqlite.SQLiteException

fun AppDatabase.Companion.isStorageFull(error: Throwable): Boolean =
    generateSequence(error) { it.cause }.any { cause ->
        cause is SQLiteException && storageFullCode.containsMatchIn(cause.message.orEmpty())
    }

private val storageFullCode = Regex("""^Error code: 13\b""")

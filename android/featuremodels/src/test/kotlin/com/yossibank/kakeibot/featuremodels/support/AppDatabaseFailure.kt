package com.yossibank.kakeibot.featuremodels.support

import androidx.room.useWriterConnection
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.types.EntryList
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import java.io.IOException

val failingEntryList: Flow<EntryList> = flow { throw IOException("failing for tests") }

suspend fun AppDatabase.failWrites(to: String) {
    useWriterConnection { connection ->
        for (event in listOf("INSERT", "UPDATE", "DELETE")) {
            val sql = """
                CREATE TRIGGER fail_${to}_${event.lowercase()} BEFORE $event ON $to
                BEGIN SELECT RAISE(ABORT, 'failing for tests'); END
            """.trimIndent()

            connection.usePrepared(sql) { it.step() }
        }
    }
}

suspend fun AppDatabase.allowWrites(to: String) {
    useWriterConnection { connection ->
        for (event in listOf("insert", "update", "delete")) {
            connection.usePrepared("DROP TRIGGER fail_${to}_$event") { it.step() }
        }
    }
}

suspend fun AppDatabase.failReads(of: String) {
    useWriterConnection { connection ->
        connection.usePrepared("DROP TABLE $of") { it.step() }
    }
}

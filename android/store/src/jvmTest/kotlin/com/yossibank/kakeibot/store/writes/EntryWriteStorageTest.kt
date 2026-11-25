package com.yossibank.kakeibot.store.writes

import androidx.room.useWriterConnection
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.isStorageFull
import com.yossibank.kakeibot.store.writes.methods.saveEntryResult
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.test.runTest
import org.junit.Test
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class EntryWriteStorageTest {
    @Test
    fun tellsStorageFullFromOtherFailures() = runTest {
        val setup = EntryWriteTest.Setup.make()
        val draft = setup.draft.copy(memo = "あ".repeat(100_000))

        setup.database.useWriterConnection { connection ->
            val pages = connection.usePrepared("PRAGMA page_count") { statement ->
                statement.step()
                statement.getLong(0)
            }

            connection.usePrepared("PRAGMA max_page_count = $pages") { it.step() }
        }

        val error = assertFailsWith<Exception> {
            setup.database.saveEntryResult(draft, at = setup.now)
        }

        assertTrue(AppDatabase.isStorageFull(error))
        assertFalse(AppDatabase.isStorageFull(CancellationException()))

        setup.database.close()
    }
}

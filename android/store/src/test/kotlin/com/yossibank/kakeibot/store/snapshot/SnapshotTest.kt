package com.yossibank.kakeibot.store.snapshot

import androidx.sqlite.SQLiteException
import com.yossibank.kakeibot.core.concepts.export.v1.ExportV1
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.records.RecordTestSample
import com.yossibank.kakeibot.store.support.StoreFixture
import com.yossibank.kakeibot.store.support.execute
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class SnapshotTest {
    @Test
    fun roundTripsFixture() = runTest {
        val database = AppDatabase.inMemory()
        val export = export()

        database.replace(export.data)
        val snapshot = database.snapshot()

        assertEquals(export.data, snapshot)

        database.close()
    }

    @Test
    fun replacesExistingRows() = runTest {
        val database = AppDatabase.inMemory()
        val sample = RecordTestSample()
        val export = export()

        sample.insert(database)

        database.replace(export.data)
        val snapshot = database.snapshot()

        assertEquals(export.data, snapshot)

        database.close()
    }

    @Test
    fun keepsRowsWhenReplaceFails() = runTest {
        val database = AppDatabase.inMemory()
        val export = export()
        val entries = export.data.entries
        val invalid = export.data.copy(entries = listOf(entries[0].copy(amount = 0)) + entries.drop(1))

        database.replace(export.data)

        assertFailsWith<SQLiteException> {
            database.replace(invalid)
        }

        val snapshot = database.snapshot()

        assertEquals(export.data, snapshot)

        database.close()
    }

    @Test
    fun skipsUnknownSettingKeys() = runTest {
        val database = AppDatabase.inMemory()
        val export = export()

        database.replace(export.data)

        database.execute("INSERT INTO setting (key, value) VALUES ('future_key', '1')")

        val snapshot = database.snapshot()

        assertEquals(export.data, snapshot)

        database.close()
    }

    @Test
    fun restoresWhatItBacksUp() = runTest {
        val database = AppDatabase.inMemory()
        val restored = AppDatabase.inMemory()
        val export = export()
        val date = Instant.ofEpochSecond(1_791_000_000)

        val app = ExportV1.App(
            platform = ExportV1.Platform.android,
            version = "1.0",
        )

        database.replace(export.data)
        val json = database.backup(date, app)
        val backup = ExportV1.of(json)

        restored.restoreBackup(
            export = backup,
            stashingAt = date,
            app = app,
        ) {}

        assertEquals(date, backup.exportedAt)
        assertEquals(app, backup.app)
        assertEquals(export.data, restored.snapshot())

        database.close()
        restored.close()
    }

    @Test
    fun stashesDatabaseInsideTheSameWrite() = runTest {
        val database = AppDatabase.inMemory()
        val sample = RecordTestSample()
        val export = export()
        val date = Instant.ofEpochSecond(1_791_000_000)
        var stashed: ByteArray? = null

        val app = ExportV1.App(
            platform = ExportV1.Platform.android,
            version = "1.0",
        )

        sample.insert(database)

        val before = database.snapshot()

        database.restoreBackup(
            export = export,
            stashingAt = date,
            app = app,
        ) { data ->
            stashed = data
        }

        val data = checkNotNull(stashed)

        assertEquals(before, ExportV1.of(data).data)
        assertEquals(export.data, database.snapshot())

        database.close()
    }

    @Test
    fun keepsRowsWhenStashFails() = runTest {
        val database = AppDatabase.inMemory()
        val sample = RecordTestSample()
        val export = export()

        val app = ExportV1.App(
            platform = ExportV1.Platform.android,
            version = "1.0",
        )

        sample.insert(database)

        val before = database.snapshot()

        assertFailsWith<StashException> {
            database.restoreBackup(
                export = export,
                stashingAt = Instant.now(),
                app = app,
            ) {
                throw StashException()
            }
        }

        assertEquals(before, database.snapshot())

        database.close()
    }

    private class StashException : Exception()

    private fun export(): ExportV1 = ExportV1.of(StoreFixture.data("export/export-v1.json"))
}

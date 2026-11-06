package com.yossibank.kakeibot.store.records

import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.records.rows.icon
import com.yossibank.kakeibot.store.records.rows.record
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals

class IconRecordTest {
    @Test
    fun roundTripsIcon() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.parse("2026-11-06T00:00:00Z")
        val icon = Icon(
            emoji = null,
            text = null,
            glyph = Icon.Glyph.other,
            color = "#FF0000",
            createdAt = now,
            updatedAt = now,
        )

        database.iconDao().insert(icon.record())

        assertEquals(icon, database.iconDao().find(icon.id.toString())?.icon())

        database.close()
    }
}

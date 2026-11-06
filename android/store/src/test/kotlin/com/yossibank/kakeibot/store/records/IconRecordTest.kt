package com.yossibank.kakeibot.store.records

import com.yossibank.kakeibot.core.concepts.icon.GlyphSerializer
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.insertDefaultsIfEmpty
import com.yossibank.kakeibot.store.records.rows.icon
import com.yossibank.kakeibot.store.support.execute
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class IconRecordTest {
    @Test
    fun readsGlyphAddedByNewerVersionAsDefault() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(1_791_000_000)
        database.insertDefaultsIfEmpty(now)

        database.execute("UPDATE icon SET glyph = 'glyph-from-newer-version'")

        val icons = database.iconDao().all().map { it.icon() }

        assertTrue(icons.isNotEmpty())
        assertTrue(icons.all { it?.glyph == Icon.Glyph.other })

        database.close()
    }

    @Test
    fun decodesUnknownGlyphInJSONAsDefault() {
        val json = "\"glyph-from-newer-version\""

        val glyph = Json.decodeFromString(GlyphSerializer, json)

        assertEquals(Icon.Glyph.other, glyph)
    }
}

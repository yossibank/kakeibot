package com.yossibank.kakeibot.store.writes

import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.setting
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.receiptSavedCount
import com.yossibank.kakeibot.store.support.execute
import com.yossibank.kakeibot.store.support.rows
import com.yossibank.kakeibot.store.writes.methods.countReceiptSave
import kotlinx.coroutines.test.runTest
import org.junit.Test
import kotlin.test.assertEquals

class ReceiptWriteTest {
    @Test
    fun countsReceiptSaves() = runTest {
        val database = AppDatabase.inMemory()

        val initial = database.setting(SettingKey.receiptSavedCount)
        database.countReceiptSave()
        database.countReceiptSave()
        val counted = database.setting(SettingKey.receiptSavedCount)
        val text = database.countText()

        assertEquals(0, initial)
        assertEquals(2, counted)
        assertEquals("2", text)

        database.close()
    }

    @Test
    fun readsBrokenCountAsZero() = runTest {
        val database = AppDatabase.inMemory()

        database.execute("INSERT INTO setting (key, value) VALUES ('receipt_saved_count', '-3')")

        val count = database.setting(SettingKey.receiptSavedCount)

        assertEquals(0, count)

        database.close()
    }
}

private suspend fun AppDatabase.countText(): String? = rows(
    "SELECT value FROM setting WHERE key = 'receipt_saved_count'",
).firstOrNull()?.get("value") as String?

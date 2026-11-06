package com.yossibank.kakeibot.store.queries

import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.notification.ReminderTime
import com.yossibank.kakeibot.core.concepts.theme.ThemeChoice
import com.yossibank.kakeibot.core.concepts.theme.ThemePreset
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.insertDefaultsIfEmpty
import com.yossibank.kakeibot.store.queries.methods.setupProgressUpdates
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.reminderTime
import com.yossibank.kakeibot.store.records.settingkeys.theme
import com.yossibank.kakeibot.store.support.setBudget
import com.yossibank.kakeibot.store.support.setSetting
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class SetupProgressTest {
    @Test
    fun followsBudgetReminderAndTheme() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(1_791_000_000)
        database.insertDefaultsIfEmpty(now)
        val month = assertNotNull(YearMonth.parse("2026-10"))
        val empty = database.setupProgressUpdates().first()

        database.setBudget(
            amount = 80000,
            from = month,
        )

        database.setSetting(
            key = SettingKey.reminderTime,
            value = ReminderTime.parse("21:00"),
        )

        database.setSetting(
            key = SettingKey.theme,
            value = ThemeChoice.Preset(ThemePreset.sky),
        )

        val filled = database.setupProgressUpdates().first()

        assertFalse(empty.hasBudget)
        assertFalse(empty.hasWalletBalance)
        assertFalse(empty.hasRecurring)
        assertFalse(empty.hasReminder)
        assertFalse(empty.hasTheme)
        assertTrue(filled.hasBudget)
        assertTrue(filled.hasReminder)
        assertTrue(filled.hasTheme)

        database.close()
    }
}

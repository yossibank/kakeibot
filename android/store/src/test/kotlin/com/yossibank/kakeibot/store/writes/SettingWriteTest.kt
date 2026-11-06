package com.yossibank.kakeibot.store.writes

import com.yossibank.kakeibot.core.concepts.date.HolidayShift
import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.core.concepts.date.Weekday
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.notification.ReminderTime
import com.yossibank.kakeibot.core.concepts.review.ReviewKind
import com.yossibank.kakeibot.core.concepts.review.ReviewPeriod
import com.yossibank.kakeibot.core.concepts.setting.LaunchScreen
import com.yossibank.kakeibot.core.concepts.setting.RecordsLayout
import com.yossibank.kakeibot.core.concepts.setting.Setting
import com.yossibank.kakeibot.core.concepts.setting.SettingsScreen
import com.yossibank.kakeibot.core.concepts.setting.TemplateOrder
import com.yossibank.kakeibot.core.concepts.theme.ThemeBackdrop
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.setting
import com.yossibank.kakeibot.store.queries.methods.settingUpdates
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.backdrop
import com.yossibank.kakeibot.store.records.settingkeys.budgetCarryoverFrom
import com.yossibank.kakeibot.store.records.settingkeys.closedHints
import com.yossibank.kakeibot.store.records.settingkeys.launchScreen
import com.yossibank.kakeibot.store.records.settingkeys.monthStartDay
import com.yossibank.kakeibot.store.records.settingkeys.onboardingCompleted
import com.yossibank.kakeibot.store.records.settingkeys.recordsLayout
import com.yossibank.kakeibot.store.records.settingkeys.reminderTime
import com.yossibank.kakeibot.store.records.settingkeys.reviewKind
import com.yossibank.kakeibot.store.records.settingkeys.reviewScale
import com.yossibank.kakeibot.store.records.settingkeys.templateOrder
import com.yossibank.kakeibot.store.records.settingkeys.weekStart
import com.yossibank.kakeibot.store.support.rows
import com.yossibank.kakeibot.store.writes.methods.setSetting
import kotlinx.coroutines.flow.produceIn
import kotlinx.coroutines.test.runTest
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class SettingWriteTest {
    @Test
    fun savesMonthStartDay() = runTest {
        val database = AppDatabase.inMemory()
        val payday = assertNotNull(MonthStartDay.of(25))
        val last = assertNotNull(MonthStartDay.of(31))

        val initial = database.setting(SettingKey.monthStartDay)
        database.setSetting(SettingKey.monthStartDay, to = payday)
        val saved = database.setting(SettingKey.monthStartDay)
        database.setSetting(SettingKey.monthStartDay, to = last)
        val changed = database.setting(SettingKey.monthStartDay)

        assertEquals(MonthStartDay.first, initial)
        assertEquals(payday, saved)
        assertTrue(changed.isLastDay)

        database.close()
    }

    @Test
    fun savesMonthStartShift() = runTest {
        val database = AppDatabase.inMemory()

        val shifted = assertNotNull(
            MonthStartDay.of(
                day = 25,
                shift = HolidayShift.previous,
            ),
        )

        val plain = assertNotNull(MonthStartDay.of(25))

        database.setSetting(SettingKey.monthStartDay, to = shifted)
        val saved = database.setting(SettingKey.monthStartDay)
        val savedText = database.settingText("month_start_shift")
        database.setSetting(SettingKey.monthStartDay, to = plain)
        val cleared = database.setting(SettingKey.monthStartDay)
        val clearedText = database.settingText("month_start_shift")

        assertEquals(shifted, saved)
        assertEquals("previous", savedText)
        assertEquals(plain, cleared)
        assertNull(clearedText)

        database.close()
    }

    @Test
    fun savesBudgetCarryoverFrom() = runTest {
        val database = AppDatabase.inMemory()
        val start = assertNotNull(YearMonth.parse("2026-11"))

        val initial = database.setting(SettingKey.budgetCarryoverFrom)
        database.setSetting(SettingKey.budgetCarryoverFrom, to = start)
        val saved = database.setting(SettingKey.budgetCarryoverFrom)
        val savedText = database.settingText("budget_carryover_from")
        database.setSetting(SettingKey.budgetCarryoverFrom, to = null)
        val cleared = database.setting(SettingKey.budgetCarryoverFrom)
        val clearedText = database.settingText("budget_carryover_from")

        assertNull(initial)
        assertEquals(start, saved)
        assertEquals("2026-11", savedText)
        assertNull(cleared)
        assertNull(clearedText)

        database.close()
    }

    @Test
    fun announcesMonthStartShift() = runTest {
        val database = AppDatabase.inMemory()
        val payday = assertNotNull(MonthStartDay.of(25))
        val shifted = payday.shifted(by = HolidayShift.next)
        database.setSetting(SettingKey.monthStartDay, to = payday)
        val updates = database.settingUpdates(SettingKey.monthStartDay).produceIn(backgroundScope)

        val initial = updates.receive()
        database.setSetting(SettingKey.monthStartDay, to = shifted)
        val changed = updates.receive()

        assertEquals(payday, initial)
        assertEquals(shifted, changed)

        database.close()
    }

    @Test
    fun savesClosedHints() = runTest {
        val database = AppDatabase.inMemory()

        val initial = database.setting(SettingKey.closedHints)

        database.setSetting(
            SettingKey.closedHints,
            to = setOf(
                SettingsScreen.wallets,
                SettingsScreen.budgets,
            ),
        )

        val saved = database.setting(SettingKey.closedHints)
        val text = database.settingText("closed_hints")

        assertTrue(initial.isEmpty())
        assertEquals(setOf(SettingsScreen.wallets, SettingsScreen.budgets), saved)
        assertEquals("budgets,wallets", text)

        database.close()
    }

    @Test
    fun announcesMonthStartDay() = runTest {
        val database = AppDatabase.inMemory()
        val payday = assertNotNull(MonthStartDay.of(25))
        val updates = database.settingUpdates(SettingKey.monthStartDay).produceIn(backgroundScope)

        val initial = updates.receive()
        database.setSetting(SettingKey.monthStartDay, to = payday)
        val changed = updates.receive()

        assertEquals(MonthStartDay.first, initial)
        assertEquals(payday, changed)

        database.close()
    }

    @Test
    fun savesWeekStart() = runTest {
        val database = AppDatabase.inMemory()
        val updates = database.settingUpdates(SettingKey.weekStart).produceIn(backgroundScope)

        val initial = updates.receive()
        database.setSetting(SettingKey.weekStart, to = Weekday.monday)
        val changed = updates.receive()
        val saved = database.setting(SettingKey.weekStart)

        assertEquals(Weekday.sunday, initial)
        assertEquals(Weekday.monday, changed)
        assertEquals(Weekday.monday, saved)

        database.close()
    }

    @Test
    fun savesAndClearsReminderTime() = runTest {
        val database = AppDatabase.inMemory()
        val time = assertNotNull(ReminderTime.parse("21:30"))

        val initial = database.setting(SettingKey.reminderTime)
        database.setSetting(SettingKey.reminderTime, to = time)
        val saved = database.setting(SettingKey.reminderTime)
        database.setSetting(SettingKey.reminderTime, to = null)
        val cleared = database.setting(SettingKey.reminderTime)

        assertNull(initial)
        assertEquals(time, saved)
        assertNull(cleared)

        database.close()
    }

    @Test
    fun announcesReminderTime() = runTest {
        val database = AppDatabase.inMemory()
        val time = assertNotNull(ReminderTime.parse("20:00"))
        val updates = database.settingUpdates(SettingKey.reminderTime).produceIn(backgroundScope)

        val initial = updates.receive()
        database.setSetting(SettingKey.reminderTime, to = time)
        val changed = updates.receive()

        assertNull(initial)
        assertEquals(time, changed)

        database.close()
    }

    @Test
    fun completesOnboarding() = runTest {
        val database = AppDatabase.inMemory()

        val before = database.setting(SettingKey.onboardingCompleted)
        database.setSetting(SettingKey.onboardingCompleted, to = true)
        val after = database.setting(SettingKey.onboardingCompleted)

        assertFalse(before)
        assertTrue(after)

        database.close()
    }

    @Test
    fun savesLaunchScreen() = runTest {
        val database = AppDatabase.inMemory()

        val initial = database.setting(SettingKey.launchScreen)
        database.setSetting(SettingKey.launchScreen, to = LaunchScreen.records)
        val saved = database.setting(SettingKey.launchScreen)

        assertEquals(LaunchScreen.home, initial)
        assertEquals(LaunchScreen.records, saved)

        database.close()
    }

    @Test
    fun savesTemplateOrder() = runTest {
        val database = AppDatabase.inMemory()

        val initial = database.setting(SettingKey.templateOrder)
        database.setSetting(SettingKey.templateOrder, to = TemplateOrder.frequent)
        val saved = database.setting(SettingKey.templateOrder)

        assertEquals(TemplateOrder.manual, initial)
        assertEquals(TemplateOrder.frequent, saved)

        database.close()
    }

    @Test
    fun savesRecordsLayout() = runTest {
        val database = AppDatabase.inMemory()

        val initial = database.setting(SettingKey.recordsLayout)
        database.setSetting(SettingKey.recordsLayout, to = RecordsLayout.list)
        val saved = database.setting(SettingKey.recordsLayout)

        assertEquals(RecordsLayout.calendar, initial)
        assertEquals(RecordsLayout.list, saved)

        database.close()
    }

    @Test
    fun readsWashiBackdropAsRuled() = runTest {
        val database = AppDatabase.inMemory()

        val saved = Setting(
            key = Setting.Key.backdrop,
            value = "washi",
        )

        database.settingDao().insert(saved.record())

        val backdrop = database.setting(SettingKey.backdrop)
        database.setSetting(SettingKey.backdrop, to = backdrop)
        val text = database.settingText("backdrop")

        assertEquals(ThemeBackdrop.ruled, backdrop)
        assertEquals("ruled", text)

        database.close()
    }

    @Test
    fun savesReviewSelection() = runTest {
        val database = AppDatabase.inMemory()

        val initialScale = database.setting(SettingKey.reviewScale)
        val initialKind = database.setting(SettingKey.reviewKind)
        database.setSetting(SettingKey.reviewScale, to = ReviewPeriod.Scale.year)
        database.setSetting(SettingKey.reviewKind, to = ReviewKind.balance)
        val scale = database.setting(SettingKey.reviewScale)
        val kind = database.setting(SettingKey.reviewKind)

        assertEquals(ReviewPeriod.Scale.month, initialScale)
        assertEquals(ReviewKind.expense, initialKind)
        assertEquals(ReviewPeriod.Scale.year, scale)
        assertEquals(ReviewKind.balance, kind)

        database.close()
    }
}

private suspend fun AppDatabase.settingText(key: String): String? = rows(
    "SELECT value FROM setting WHERE key = ?",
    key,
).firstOrNull()?.get("value") as String?

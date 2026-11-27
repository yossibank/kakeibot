package com.yossibank.kakeibot.featuremodels.screens.settings.menu

import com.yossibank.kakeibot.core.concepts.date.HolidayShift
import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.core.concepts.date.Weekday
import com.yossibank.kakeibot.featuremodels.shared.period.PeriodText
import com.yossibank.kakeibot.featuremodels.shared.period.keepingShift
import com.yossibank.kakeibot.featuremodels.support.ModelTestSetup
import com.yossibank.kakeibot.featuremodels.support.ModelWait
import com.yossibank.kakeibot.featuremodels.support.failWrites
import com.yossibank.kakeibot.featuremodels.support.modelTest
import com.yossibank.kakeibot.store.queries.methods.setting
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.monthStartDay
import com.yossibank.kakeibot.store.records.settingkeys.weekStart
import kotlinx.coroutines.launch
import org.junit.Test
import kotlin.test.assertEquals

class SettingsMenuModelTest {
    @Test
    fun savesChosenDay() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.observedModel()

        model.choose(weekStart = Weekday.wednesday)
        ModelWait.until { model.input.weekStart == Weekday.wednesday }

        assertEquals(Weekday.wednesday, setup.database.setting(SettingKey.weekStart))
        assertEquals("", model.state.errorNotice.message)
    }

    @Test
    fun tellsWhenSavingFails() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.observedModel()
        val before = model.input.weekStart
        setup.database.failWrites(to = "setting")

        model.choose(weekStart = Weekday.wednesday)

        assertEquals(before, model.input.weekStart)
        assertEquals(before, setup.database.setting(SettingKey.weekStart))
        assertEquals("設定を保存できませんでした", model.state.errorNotice.message)
    }

    @Test
    fun tellsWhenMonthStartCannotBeSaved() = modelTest(today = "2026-10-17") { setup ->
        val payday = checkNotNull(MonthStartDay.of(day = 25))
        val model = setup.observedModel()
        setup.database.failWrites(to = "setting")

        model.choose(monthStartDay = payday)

        assertEquals(MonthStartDay.first, model.input.monthStartDay)
        assertEquals(MonthStartDay.first, setup.database.setting(SettingKey.monthStartDay))
        assertEquals("設定を保存できませんでした", model.state.errorNotice.message)
    }

    @Test
    fun keepsLaterChoiceWhenEarlierSaveFails() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.observedModel()
        setup.database.failWrites(to = "setting", containing = "monday")

        val first = launch { model.choose(weekStart = Weekday.monday) }
        val second = launch { model.choose(weekStart = Weekday.tuesday) }
        first.join()
        second.join()
        ModelWait.until { model.input.weekStart == Weekday.tuesday }

        assertEquals(Weekday.tuesday, setup.database.setting(SettingKey.weekStart))
        assertEquals("設定を保存できませんでした", model.state.errorNotice.message)
    }

    @Test
    fun returnsToSavedDayWhenBothQuickSavesFail() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.observedModel()
        setup.database.failWrites(to = "setting")

        val first = launch { model.choose(weekStart = Weekday.monday) }
        val second = launch { model.choose(weekStart = Weekday.tuesday) }
        first.join()
        second.join()

        assertEquals(Weekday.sunday, model.input.weekStart)
        assertEquals(Weekday.sunday, setup.database.setting(SettingKey.weekStart))
        assertEquals(2, model.state.errorNotice.count)
    }

    @Test
    fun choosesAndSavesStartDay() = modelTest(today = "2026-10-12") { setup ->
        val payday = checkNotNull(MonthStartDay.of(day = 25))
        val model = setup.observedModel()
        val start = model.input.monthStartDay
        val initial = PeriodText.current(startingOn = start, today = setup.today)

        model.choose(monthStartDay = payday)
        ModelWait.until { model.input.monthStartDay == payday }
        val chosen = model.input.monthStartDay

        assertEquals("10/1〜10/31", initial)
        assertEquals("9/25〜10/24", PeriodText.current(startingOn = chosen, today = setup.today))
        assertEquals(10, setup.today.periodMonth(startingOn = chosen).month)
        assertEquals(payday, setup.database.setting(SettingKey.monthStartDay))
    }

    @Test
    fun keepsShiftWhenChangingDay() = modelTest(today = "2026-10-12") { setup ->
        val payday = checkNotNull(MonthStartDay.of(day = 25))
        val earlier = checkNotNull(MonthStartDay.of(day = 20))
        val model = setup.observedModel()

        val plainNote = PeriodText.shiftNote(startingOn = payday, today = setup.today)
        val shifted = payday.shifted(by = HolidayShift.previous)
        val shiftedText = PeriodText.current(startingOn = shifted, today = setup.today)
        val weekdayNote = PeriodText.shiftNote(startingOn = shifted, today = setup.today)
        val kept = earlier.keepingShift(of = shifted)
        model.choose(monthStartDay = kept)
        ModelWait.until { model.input.monthStartDay == kept }

        assertEquals("土日・祝日でも、そのまま数えます", plainNote)
        assertEquals("9/25〜10/22", shiftedText)
        assertEquals("今の期間の始まりは、平日です", weekdayNote)
        assertEquals("9/18〜10/19", PeriodText.current(startingOn = kept, today = setup.today))
        assertEquals(
            "9/20（日）を 9/18（金）にずらしています",
            PeriodText.shiftNote(startingOn = kept, today = setup.today),
        )
        assertEquals(
            earlier.shifted(by = HolidayShift.previous),
            setup.database.setting(SettingKey.monthStartDay),
        )
    }

    private suspend fun ModelTestSetup.observedModel(): SettingsMenuModel {
        val model = SettingsMenuModel(parts = parts)
        val saved = database.setting(SettingKey.weekStart)

        scope.launch { model.observe() }
        ModelWait.until { model.input.weekStart == saved }

        return model
    }
}

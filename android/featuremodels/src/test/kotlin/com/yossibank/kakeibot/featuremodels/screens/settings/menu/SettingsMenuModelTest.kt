package com.yossibank.kakeibot.featuremodels.screens.settings.menu

import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.core.concepts.date.Weekday
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

        model.store(
            key = SettingKey.weekStart,
            value = Weekday.wednesday,
        )
        ModelWait.until { model.input.weekStart == Weekday.wednesday }

        assertEquals(Weekday.wednesday, setup.database.setting(SettingKey.weekStart))
        assertEquals("", model.state.task.message)
    }

    @Test
    fun tellsWhenSavingFails() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.observedModel()
        val before = model.input.weekStart
        setup.database.failWrites(to = "setting")

        model.store(
            key = SettingKey.weekStart,
            value = Weekday.wednesday,
        )

        assertEquals(before, model.input.weekStart)
        assertEquals(before, setup.database.setting(SettingKey.weekStart))
        assertEquals("設定を保存できませんでした", model.state.task.message)
    }

    @Test
    fun tellsWhenMonthStartCannotBeSaved() = modelTest(today = "2026-10-17") { setup ->
        val payday = checkNotNull(MonthStartDay.of(day = 25))
        val model = setup.observedModel()
        setup.database.failWrites(to = "setting")

        model.store(
            key = SettingKey.monthStartDay,
            value = payday,
        )

        assertEquals(MonthStartDay.first, model.input.monthStartDay)
        assertEquals(MonthStartDay.first, setup.database.setting(SettingKey.monthStartDay))
        assertEquals("設定を保存できませんでした", model.state.task.message)
    }

    private suspend fun ModelTestSetup.observedModel(): SettingsMenuModel {
        val model = SettingsMenuModel(database = database)
        val saved = database.setting(SettingKey.weekStart)

        scope.launch { model.observe() }
        ModelWait.until { model.input.weekStart == saved }

        return model
    }
}

package com.yossibank.kakeibot.featuremodels.screens.tabs.records.model

import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.core.concepts.date.Weekday
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryDraft
import com.yossibank.kakeibot.core.concepts.setting.RecordsLayout
import com.yossibank.kakeibot.featuremodels.shared.model.ObservationRound
import com.yossibank.kakeibot.featuremodels.support.ModelTestSetup
import com.yossibank.kakeibot.featuremodels.support.ModelTestSetup.Companion.date
import com.yossibank.kakeibot.featuremodels.support.ModelWait
import com.yossibank.kakeibot.featuremodels.support.failReads
import com.yossibank.kakeibot.featuremodels.support.failWrites
import com.yossibank.kakeibot.featuremodels.support.failingEntryList
import com.yossibank.kakeibot.featuremodels.support.failingFirst
import com.yossibank.kakeibot.featuremodels.support.modelTest
import com.yossibank.kakeibot.store.queries.methods.entryListUpdates
import com.yossibank.kakeibot.store.queries.methods.setting
import com.yossibank.kakeibot.store.queries.methods.settingUpdates
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.monthStartDay
import com.yossibank.kakeibot.store.records.settingkeys.recordsLayout
import com.yossibank.kakeibot.store.records.settingkeys.weekStart
import com.yossibank.kakeibot.store.writes.methods.saveEntry
import com.yossibank.kakeibot.store.writes.methods.setSetting
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class RecordsModelTest {
    @Test
    fun loadsOnlyAfterListArrives() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.recordsModel()
        val before = model.input.list.isLoaded

        backgroundScope.launch { model.observe() }
        ModelWait.until { model.input.list.isLoaded }

        assertFalse(before)
        assertTrue(model.output.days.isEmpty())
        assertEquals(0L, model.output.balance)
    }

    @Test
    fun showsOnlyDaysInMonth() = modelTest(today = "2026-10-17") { setup ->
        setup.save(Entry.Kind.expense, amount = 980, on = date("2026-10-12"))
        setup.save(Entry.Kind.income, amount = 250_000, on = date("2026-10-10"))
        setup.save(Entry.Kind.expense, amount = 3980, on = date("2026-10-10"))
        setup.save(Entry.Kind.expense, amount = 500, on = date("2026-09-30"))
        val model = setup.observedModel()

        assertEquals(
            listOf("2026-10-12", "2026-10-10"),
            model.output.days.map {
                it.date.toString()
            },
        )
        assertEquals(4960L, model.output.expenseTotal)
        assertEquals(250_000L, model.output.incomeTotal)
        assertEquals(245_040L, model.output.balance)
        assertEquals("収支 · 黒字", model.output.balanceTitle)

        model.move(months = -1)

        assertEquals("2026-09", model.output.shownMonth.toString())
        assertEquals(listOf("2026-09-30"), model.output.days.map { it.date.toString() })
        assertEquals(500L, model.output.expenseTotal)
        assertEquals("収支 · 赤字", model.output.balanceTitle)
    }

    @Test
    fun keepsMonthWhenObservingAgain() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.recordsModel()
        val first = backgroundScope.launch { model.observe() }
        ModelWait.until { model.input.list.isLoaded }

        first.cancelAndJoin()
        model.move(months = -1)
        setup.save(Entry.Kind.expense, amount = 500, on = date("2026-09-30"))
        backgroundScope.launch { model.observe() }
        ModelWait.until { model.output.days.size == 1 }
        setup.database.setSetting(key = SettingKey.weekStart, to = Weekday.monday)
        ModelWait.until { model.input.weekStart == Weekday.monday }

        assertEquals("2026-09", model.state.month.toString())
    }

    @Test
    fun describesMonthAndPeriod() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.observedModel()

        assertEquals("2026年 10月", model.output.monthTitle)
        assertEquals("10/1〜10/31", model.output.periodText)

        model.move(months = 3)

        assertEquals("2027年 1月", model.output.monthTitle)
        assertEquals("1/1〜1/31", model.output.periodText)
    }

    @Test
    fun followsMonthStartDaySetting() = modelTest(today = "2026-10-17") { setup ->
        setup.database.setSetting(
            key = SettingKey.monthStartDay,
            to = checkNotNull(MonthStartDay.of(day = 25)),
        )
        setup.save(Entry.Kind.expense, amount = 500, on = date("2026-09-24"))
        setup.save(Entry.Kind.expense, amount = 700, on = date("2026-09-25"))
        val model = setup.recordsModel()

        backgroundScope.launch { model.observe() }
        ModelWait.until { model.input.list.isLoaded && model.input.monthStartDay.day == 25 }

        assertEquals("2026-10", model.output.shownMonth.toString())
        assertEquals("9/25〜10/24", model.output.periodText)
        assertEquals(listOf("2026-09-25"), model.output.days.map { it.date.toString() })
    }

    @Test
    fun returnsToCurrentPeriodWhenMonthStartDayChanges() = modelTest(
        today = "2026-10-17",
    ) { setup ->
        val model = setup.observedModel()
        model.move(months = -3)
        val moved = model.output.shownMonth.toString()

        setup.database.setSetting(
            key = SettingKey.monthStartDay,
            to = checkNotNull(MonthStartDay.of(day = 25)),
        )
        ModelWait.until { model.input.monthStartDay.day == 25 }

        assertEquals("2026-07", moved)
        assertEquals("2026-10", model.output.shownMonth.toString())
        assertEquals("9/25〜10/24", model.output.periodText)
    }

    @Test
    fun startsWeekOnSundayBeforeSettingArrives() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.recordsModel()

        assertEquals(Weekday.sunday, model.output.weekdays.first())
        assertEquals("2026-10-01", model.output.weeks.first()[4].toString())
    }

    @Test
    fun startsWeekOnSetting() = modelTest(today = "2026-10-17") { setup ->
        setup.database.setSetting(key = SettingKey.weekStart, to = Weekday.monday)
        val model = setup.recordsModel()

        backgroundScope.launch { model.observe() }
        ModelWait.until { model.input.weekStart == Weekday.monday }

        assertEquals(Weekday.monday, model.output.weekdays.first())
        assertEquals(null, model.output.weeks.first().first())
        assertEquals("2026-10-01", model.output.weeks.first()[3].toString())
    }

    @Test
    fun showsTodayUntilAnotherDayIsChosen() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.recordsModel()
        val chosen = date("2026-10-03")

        val initial = model.output.selectedDate
        model.state.select(chosen)
        val selected = model.output.selectedDate
        model.move(months = -1)
        val moved = model.output.selectedDate

        assertEquals(setup.today, initial)
        assertEquals(chosen, selected)
        assertEquals("2026-09-01", moved.toString())
        assertNull(model.state.selected)
    }

    @Test
    fun followsTodayWhenDateChanges() = modelTest(today = "2026-10-31") { setup ->
        val model = setup.recordsModel()

        model.state.today = date("2026-11-01")

        assertEquals("2026-11", model.output.shownMonth.toString())
        assertEquals(date("2026-11-01"), model.output.selectedDate)
    }

    @Test
    fun describesRowsWithMemoAndWallet() = modelTest(today = "2026-10-17") { setup ->
        setup.save(Entry.Kind.expense, amount = 980, on = date("2026-10-12"), memo = "ランチ")
        setup.save(Entry.Kind.expense, amount = 220, on = date("2026-10-12"))
        val model = setup.observedModel()

        val day = checkNotNull(model.output.day(on = date("2026-10-12")))
        val rows = model.output.rows(of = day)

        assertEquals(listOf("財布", "財布"), rows.map { it.detail })
        assertEquals(listOf(null, "ランチ"), rows.map { it.memo })
        assertEquals(listOf(Entry.Kind.expense, Entry.Kind.expense), rows.map { it.type })
        assertNull(model.output.day(on = date("2026-10-13")))
    }

    @Test
    fun describesFeeRowWithTransferRoute() = modelTest(today = "2026-10-17") { setup ->
        val options = setup.options()

        val draft = EntryDraft(
            type = Entry.Kind.transfer,
            amount = 10000,
            date = date("2026-10-12"),
            categoryId = null,
            walletId = options.wallets[1].id,
            toWalletId = options.wallets[0].id,
            fee = 110,
        )

        setup.database.saveEntry(draft, at = setup.now)
        val model = setup.observedModel()

        val day = checkNotNull(model.output.days.firstOrNull())
        val routes = model.output.rows(of = day).mapNotNull { it.route?.text }

        assertTrue("銀行 → 財布 の手数料" in routes)
        assertTrue("銀行 → 財布" in routes)
        assertEquals(110L, model.output.expenseTotal)
    }

    @Test
    fun savesChosenLayout() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.observedModel()

        model.select(layout = RecordsLayout.list)

        assertEquals(RecordsLayout.list, model.input.layout)
        assertEquals(
            RecordsLayout.list,
            setup.database.settingUpdates(SettingKey.recordsLayout).first(),
        )
    }

    @Test
    fun tellsWhenLayoutCannotBeSaved() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.observedModel()
        setup.database.failWrites(to = "setting")

        model.select(layout = RecordsLayout.list)

        assertEquals(RecordsLayout.list, model.input.layout)
        assertEquals(RecordsLayout.calendar, setup.database.setting(SettingKey.recordsLayout))
        assertEquals("保存できませんでした", model.state.task.message)
    }

    @Test
    fun showsNoticeWhenListFails() = modelTest(today = "2026-10-17") { setup ->
        val model = RecordsModel(
            parts = setup.parts(entryList = failingEntryList),
            today = setup.today,
            round = ObservationRound(),
        )

        setup.scope.launch { model.observe() }
        ModelWait.until { model.state.task.message.isNotEmpty() }
        setup.database.setSetting(key = SettingKey.weekStart, to = Weekday.sunday)
        ModelWait.until { model.input.weekStart == Weekday.sunday }

        assertEquals("記録を読めませんでした", model.state.task.message)
        assertFalse(model.input.list.isLoaded)
        assertNull(model.input.list.value)
    }

    @Test
    fun marksListFailureUntilRetried() = modelTest(today = "2026-10-17") { setup ->
        val model = RecordsModel(
            parts = setup.parts(
                entryList = setup.database.entryListUpdates().failingFirst(times = 4),
            ),
            today = setup.today,
            round = ObservationRound(),
        )

        setup.scope.launch { model.observe() }
        ModelWait.until { model.input.list.isFailed }
        val message = model.state.task.message
        val list = model.input.list.value
        model.retry()
        ModelWait.until { model.input.list.isLoaded }

        assertEquals("記録を読めませんでした", message)
        assertNull(list)
        assertFalse(model.input.list.isFailed)
    }

    @Test
    fun marksNoListFailureWhenSettingsFail() = modelTest(today = "2026-10-17") { setup ->
        setup.database.failReads(of = "setting")
        val model = setup.recordsModel()

        setup.scope.launch { model.observe() }
        ModelWait.until { model.state.task.message.isNotEmpty() }

        assertFalse(model.input.list.isFailed)
    }

    @Test
    fun showsNoticeWhenSettingsFail() = modelTest(today = "2026-10-17") { setup ->
        setup.database.failReads(of = "setting")
        val model = setup.recordsModel()

        setup.scope.launch { model.observe() }
        ModelWait.until { model.state.task.message.isNotEmpty() }
        ModelWait.until { model.input.list.isLoaded }

        assertEquals("記録を読めませんでした", model.state.task.message)
        assertEquals(MonthStartDay.first, model.input.monthStartDay)
    }

    private fun ModelTestSetup.recordsModel() = RecordsModel(
        parts = parts,
        today = today,
        round = ObservationRound(),
    )

    private suspend fun ModelTestSetup.observedModel(): RecordsModel {
        val model = recordsModel()

        scope.launch { model.observe() }
        ModelWait.until { model.input.list.isLoaded }

        return model
    }
}

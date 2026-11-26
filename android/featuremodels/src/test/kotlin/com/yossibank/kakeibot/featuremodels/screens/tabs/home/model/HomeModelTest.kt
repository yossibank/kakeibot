package com.yossibank.kakeibot.featuremodels.screens.tabs.home.model

import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.featuremodels.shared.model.ObservationRound
import com.yossibank.kakeibot.featuremodels.support.ModelTestSetup
import com.yossibank.kakeibot.featuremodels.support.ModelTestSetup.Companion.date
import com.yossibank.kakeibot.featuremodels.support.ModelWait
import com.yossibank.kakeibot.featuremodels.support.failingEntryList
import com.yossibank.kakeibot.featuremodels.support.failingFirst
import com.yossibank.kakeibot.featuremodels.support.modelTest
import com.yossibank.kakeibot.store.queries.methods.entryListUpdates
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.monthStartDay
import com.yossibank.kakeibot.store.writes.methods.setBudget
import com.yossibank.kakeibot.store.writes.methods.setSetting
import kotlinx.coroutines.launch
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class HomeModelTest {
    @Test
    fun showsNoticeWhenListFails() = modelTest(today = "2026-10-12") { setup ->
        val model = HomeModel(
            parts = setup.parts(entryList = failingEntryList),
            today = setup.today,
            round = ObservationRound(),
        )

        setup.scope.launch { model.observe() }
        ModelWait.until { model.state.task.message.isNotEmpty() }

        assertEquals("記録を読めませんでした", model.state.task.message)
        assertNull(model.input.overview.value)
    }

    @Test
    fun marksListFailureUntilRetried() = modelTest(today = "2026-10-12") { setup ->
        val model = HomeModel(
            parts = setup.parts(
                entryList = setup.database.entryListUpdates().failingFirst(times = 4),
            ),
            today = setup.today,
            round = ObservationRound(),
        )

        setup.scope.launch { model.observe() }
        ModelWait.until { model.input.overview.isFailed }
        val message = model.state.task.message
        val overview = model.input.overview.value
        model.retry()
        ModelWait.until { model.input.overview.isLoaded }

        assertEquals("記録を読めませんでした", message)
        assertNull(overview)
        assertFalse(model.input.overview.isFailed)
    }

    @Test
    fun showsNoNoticeWhileListArrives() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.observedModel()

        assertEquals("", model.state.task.message)
    }

    @Test
    fun showsNoRecordsOnlyAfterListArrives() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.homeModel()
        val before = model.output.showsNoRecords

        assertNull(model.output.month)
        assertEquals("", model.output.periodText)
        assertNull(model.output.usage)
        assertTrue(model.output.recentRows.isEmpty())

        setup.scope.launch { model.observe() }
        ModelWait.until { model.input.overview.isLoaded }

        assertFalse(before)
        assertTrue(model.output.showsNoRecords)
    }

    @Test
    fun swapsMiddleFigureByBudget() = modelTest(today = "2026-10-12") { setup ->
        setup.save(Entry.Kind.expense, amount = 980, daysAgo = 0)
        setup.save(Entry.Kind.expense, amount = 4500, daysAgo = 1)
        val model = setup.observedModel()

        val title = model.output.middleTitle
        val amount = model.output.middleAmount
        setup.database.setBudget(amount = 120_000, categoryId = null, from = setup.today.yearMonth)
        ModelWait.until { model.output.usage != null }

        assertEquals("昨日の支出", title)
        assertEquals(4500L, amount)
        assertEquals("今月の支出", model.output.middleTitle)
        assertEquals(5480L, model.output.middleAmount)
    }

    @Test
    fun sumsMonthTodayAndYesterday() = modelTest(today = "2026-10-12") { setup ->
        setup.save(Entry.Kind.expense, amount = 980, daysAgo = 0)
        setup.save(Entry.Kind.expense, amount = 220, daysAgo = 0)
        setup.save(Entry.Kind.expense, amount = 4500, daysAgo = 1)
        setup.save(Entry.Kind.income, amount = 250_000, daysAgo = 2)
        setup.save(Entry.Kind.expense, amount = 3000, daysAgo = 30)
        val model = setup.observedModel()
        val overview = checkNotNull(model.input.overview.value)

        assertEquals(5700L, overview.monthExpense)
        assertEquals(250_000L, overview.monthIncome)
        assertEquals(1200L, overview.todayExpense)
        assertEquals(4500L, overview.yesterdayExpense)
        assertEquals("2026-10", model.output.month.toString())
        assertEquals("10/1〜10/31", model.output.periodText)
    }

    @Test
    fun showsRemainingBudgetOfPeriod() = modelTest(today = "2026-10-12") { setup ->
        setup.save(Entry.Kind.expense, amount = 45000, daysAgo = 0)
        val model = setup.observedModel()
        val before = model.output.usage

        setup.database.setBudget(amount = 120_000, categoryId = null, from = setup.today.yearMonth)
        ModelWait.until { model.output.usage != null }

        assertNull(before)
        assertEquals(75000L, model.output.usage?.remaining)
    }

    @Test
    fun followsTodayIntoNextMonth() = modelTest(today = "2026-10-31") { setup ->
        setup.save(Entry.Kind.expense, amount = 980, on = date("2026-10-31"))
        setup.save(Entry.Kind.expense, amount = 300, on = date("2026-11-01"))
        val model = setup.observedModel()

        model.state.today = date("2026-11-01")
        ModelWait.until { model.output.month.toString() == "2026-11" }

        assertEquals("11/1〜11/30", model.output.periodText)
        assertEquals(300L, model.input.overview.value?.monthExpense)
    }

    @Test
    fun listsRecentEntriesNewestFirst() = modelTest(today = "2026-10-12") { setup ->
        for (daysAgo in 0 until 7) {
            setup.save(
                Entry.Kind.expense,
                amount = 100 + daysAgo,
                daysAgo = daysAgo,
                memo = "メモ$daysAgo",
            )
        }

        val model = setup.observedModel()
        val rows = model.output.recentRows

        assertEquals(listOf(100, 101, 102, 103, 104), rows.map { it.amount })
        assertEquals("食費", rows.first().title)
        assertEquals("今日・財布", rows.first().detail)
        assertEquals("昨日・財布", rows[1].detail)
        assertEquals("10/10・財布", rows[2].detail)
        assertEquals("メモ0", rows.first().memo)
    }

    @Test
    fun ordersSameDayByNewestSave() = modelTest(today = "2026-10-12") { setup ->
        setup.save(Entry.Kind.expense, amount = 100, daysAgo = 0)
        setup.save(Entry.Kind.expense, amount = 200, daysAgo = 0)
        setup.save(Entry.Kind.expense, amount = 300, on = date("2026-10-20"))
        val model = setup.observedModel()

        assertEquals(listOf(300, 200, 100), model.output.recentRows.map { it.amount })
    }

    @Test
    fun labelsTodayAndYesterdayRows() = modelTest(today = "2026-10-12") { setup ->
        setup.save(Entry.Kind.expense, amount = 100, daysAgo = 0)
        setup.save(Entry.Kind.expense, amount = 101, daysAgo = 1)
        setup.save(Entry.Kind.expense, amount = 102, daysAgo = 2)
        setup.save(Entry.Kind.expense, amount = 103, on = date("2026-10-13"))
        val model = setup.observedModel()
        val rows = model.output.recentRows

        assertEquals(
            listOf("10/13・財布", "今日・財布", "昨日・財布", "10/10・財布"),
            rows.map { it.detail },
        )
    }

    @Test
    fun relabelsRowsWhenTodayChanges() = modelTest(today = "2026-10-12") { setup ->
        setup.save(Entry.Kind.expense, amount = 100, daysAgo = 0)
        setup.save(Entry.Kind.expense, amount = 101, daysAgo = 1)
        val model = setup.observedModel()

        model.state.today = date("2026-10-13")
        ModelWait.until { model.output.recentRows.first().detail == "昨日・財布" }

        assertEquals(
            listOf("昨日・財布", "10/11・財布"),
            model.output.recentRows.map { it.detail },
        )
    }

    @Test
    fun countsHomeByPeriod() = modelTest(today = "2026-10-12") { setup ->
        setup.save(Entry.Kind.expense, amount = 980, daysAgo = 0)
        setup.save(Entry.Kind.expense, amount = 500, daysAgo = 17)
        setup.save(Entry.Kind.expense, amount = 3000, daysAgo = 18)
        setup.database.setSetting(
            key = SettingKey.monthStartDay,
            to = checkNotNull(MonthStartDay.of(day = 25)),
        )

        val model = setup.observedModel()
        ModelWait.until { model.output.periodText == "9/25〜10/24" }

        assertEquals(1480L, model.input.overview.value?.monthExpense)
    }

    private fun ModelTestSetup.homeModel() = HomeModel(
        parts = parts,
        today = today,
        round = ObservationRound(),
    )

    private suspend fun ModelTestSetup.observedModel(): HomeModel {
        val model = homeModel()

        scope.launch { model.observe() }
        ModelWait.until { model.input.overview.isLoaded }

        return model
    }
}

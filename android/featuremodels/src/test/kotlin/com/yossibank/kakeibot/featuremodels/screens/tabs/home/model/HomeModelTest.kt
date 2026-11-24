package com.yossibank.kakeibot.featuremodels.screens.tabs.home.model

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.featuremodels.support.ModelTestSetup
import com.yossibank.kakeibot.featuremodels.support.ModelTestSetup.Companion.date
import com.yossibank.kakeibot.featuremodels.support.ModelWait
import com.yossibank.kakeibot.featuremodels.support.modelTest
import com.yossibank.kakeibot.store.queries.methods.entryListUpdates
import com.yossibank.kakeibot.store.writes.methods.setBudget
import kotlinx.coroutines.launch
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class HomeModelTest {
    @Test
    fun showsNothingBeforeOverviewArrives() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.homeModel()

        assertNull(model.output.month)
        assertEquals("", model.output.periodText)
        assertNull(model.output.usage)
        assertTrue(model.output.recentRows.isEmpty())
    }

    @Test
    fun sumsMonthTodayAndYesterday() = modelTest(today = "2026-10-12") { setup ->
        setup.save(Entry.Kind.expense, amount = 980, daysAgo = 0)
        setup.save(Entry.Kind.expense, amount = 220, daysAgo = 0)
        setup.save(Entry.Kind.expense, amount = 4500, daysAgo = 1)
        setup.save(Entry.Kind.income, amount = 250_000, daysAgo = 2)
        setup.save(Entry.Kind.expense, amount = 3000, daysAgo = 30)
        val model = setup.observedModel()
        val overview = checkNotNull(model.input.overview)

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
        assertEquals(300L, model.input.overview?.monthExpense)
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

    private fun ModelTestSetup.homeModel() = HomeModel(
        database = database,
        entryList = database.entryListUpdates(),
        today = today,
    )

    private suspend fun ModelTestSetup.observedModel(): HomeModel {
        val model = homeModel()

        scope.launch { model.observe() }
        ModelWait.until { model.input.overview != null }

        return model
    }
}

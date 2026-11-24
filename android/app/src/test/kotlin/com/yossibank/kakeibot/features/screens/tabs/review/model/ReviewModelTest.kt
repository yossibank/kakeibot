package com.yossibank.kakeibot.features.screens.tabs.review.model

import com.yossibank.kakeibot.core.concepts.date.Weekday
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.review.ReviewPeriod
import com.yossibank.kakeibot.features.support.ModelTestSetup
import com.yossibank.kakeibot.features.support.ModelTestSetup.Companion.date
import com.yossibank.kakeibot.features.support.ModelWait
import com.yossibank.kakeibot.features.support.modelTest
import com.yossibank.kakeibot.store.queries.methods.entryListUpdates
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.weekStart
import com.yossibank.kakeibot.store.writes.methods.setSetting
import kotlinx.coroutines.launch
import org.junit.Ignore
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ReviewModelTest {
    @Test
    fun comparesWithSameDaysOfPreviousMonth() = modelTest(today = "2026-10-17") { setup ->
        setup.save(Entry.Kind.expense, amount = 980, on = date("2026-10-12"))
        setup.save(Entry.Kind.expense, amount = 3000, on = date("2026-10-05"))
        setup.save(Entry.Kind.income, amount = 250_000, on = date("2026-10-10"))
        setup.save(Entry.Kind.expense, amount = 5000, on = date("2026-09-10"))
        setup.save(Entry.Kind.expense, amount = 7000, on = date("2026-09-20"))
        val model = setup.observedModel()

        assertEquals(3980L, model.output.total)
        assertEquals(5000L, model.output.previousTotal)

        model.state.kind = Entry.Kind.income

        assertEquals(250_000L, model.output.total)
        assertEquals(0L, model.output.previousTotal)
    }

    @Test
    fun comparesWholePreviousMonthWhenFinished() = modelTest(today = "2026-10-17") { setup ->
        setup.save(Entry.Kind.expense, amount = 3000, on = date("2026-09-05"))
        setup.save(Entry.Kind.expense, amount = 7000, on = date("2026-09-20"))
        setup.save(Entry.Kind.expense, amount = 2000, on = date("2026-08-25"))
        val model = setup.observedModel()

        model.state.move(count = -1)

        assertEquals(10000L, model.output.total)
        assertEquals(2000L, model.output.previousTotal)
    }

    @Test
    fun ranksCategoriesByAmount() = modelTest(today = "2026-10-17") { setup ->
        val options = setup.options()
        val food = options.expenseCategories[0]
        val daily = options.expenseCategories[1]
        setup.save(Entry.Kind.expense, amount = 500, on = date("2026-10-12"))
        setup.save(Entry.Kind.expense, amount = 1500, on = date("2026-10-13"))
        setup.save(
            Entry.Kind.expense,
            amount = 6000,
            on = date("2026-10-14"),
            categoryId = daily.id,
        )
        val model = setup.observedModel()
        val rows = model.output.rows

        assertEquals(listOf(daily.name, food.name), rows.map { it.name })
        assertEquals(listOf(6000L, 2000L), rows.map { it.amount })
        assertEquals(listOf(0.75, 0.25), rows.map { it.ratio })
        assertEquals(listOf(daily.id.toString(), food.id.toString()), rows.map { it.key })
    }

    @Test
    fun showsNoRowsWithoutTotal() = modelTest(today = "2026-10-17") { setup ->
        setup.save(Entry.Kind.expense, amount = 500, on = date("2026-10-12"))
        val model = setup.observedModel()

        model.state.kind = Entry.Kind.income

        assertEquals(0L, model.output.total)
        assertTrue(model.output.rows.isEmpty())
    }

    @Test
    fun movesPeriodAndResetsOnScale() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.reviewModel()

        val current = model.output.period.range.start
        model.state.move(count = -2)
        val earlier = model.output.period.range.start
        val earlierTitle = model.output.title
        model.state.select(scale = ReviewPeriod.Scale.year)
        val year = model.output.period.range

        assertEquals("2026-10-01", current.toString())
        assertEquals("2026-08-01", earlier.toString())
        assertEquals("2026年 8月", earlierTitle)
        assertEquals("2026-01-01", year.start.toString())
        assertEquals("2026-12-31", year.endInclusive.toString())
        assertEquals("2026年", model.output.title)
        assertEquals("1/1〜12/31", model.output.rangeText)
        assertEquals(0, model.state.offset)
    }

    @Test
    fun startsWeekOnSetting() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.reviewModel()
        model.state.select(scale = ReviewPeriod.Scale.week)
        val monday = model.output.title

        setup.database.setSetting(key = SettingKey.weekStart, to = Weekday.sunday)
        setup.scope.launch { model.observe() }
        ModelWait.until { model.input.weekStart == Weekday.sunday }

        assertEquals("10/12〜10/18", monday)
        assertEquals("10/11〜10/17", model.output.title)
    }

    @Ignore("iOS は今の期間より先へ進めない。Android は先の期間へ進める")
    @Test
    fun movesOnlyUpToCurrentPeriod() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.reviewModel()

        model.state.move(count = 1)

        assertEquals("2026-10-01", model.output.period.range.start.toString())
    }

    private fun ModelTestSetup.reviewModel() = ReviewModel(
        database = database,
        entryList = database.entryListUpdates(),
        today = today,
    )

    private suspend fun ModelTestSetup.observedModel(): ReviewModel {
        val model = reviewModel()

        scope.launch { model.observe() }
        ModelWait.until { model.input.list != null }

        return model
    }
}

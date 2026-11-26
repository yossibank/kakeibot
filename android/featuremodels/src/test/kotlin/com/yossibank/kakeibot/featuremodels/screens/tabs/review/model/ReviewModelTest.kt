package com.yossibank.kakeibot.featuremodels.screens.tabs.review.model

import com.yossibank.kakeibot.core.concepts.date.Weekday
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryDay
import com.yossibank.kakeibot.core.concepts.review.ReviewKind
import com.yossibank.kakeibot.core.concepts.review.ReviewPeriod
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.featuremodels.shared.model.ObservationRound
import com.yossibank.kakeibot.featuremodels.support.ModelTestSetup
import com.yossibank.kakeibot.featuremodels.support.ModelTestSetup.Companion.date
import com.yossibank.kakeibot.featuremodels.support.ModelWait
import com.yossibank.kakeibot.featuremodels.support.modelTest
import com.yossibank.kakeibot.store.queries.methods.entryList
import com.yossibank.kakeibot.store.queries.methods.setting
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.reviewKind
import com.yossibank.kakeibot.store.records.settingkeys.reviewScale
import com.yossibank.kakeibot.store.records.settingkeys.weekStart
import com.yossibank.kakeibot.store.writes.methods.setSetting
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.launch
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
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

        model.setKind(ReviewKind.income)

        assertEquals(250_000L, model.output.total)
        assertEquals(0L, model.output.previousTotal)

        model.setKind(ReviewKind.balance)

        assertEquals(246_020L, model.output.total)
        assertEquals(-5000L, model.output.previousTotal)
        assertTrue(model.output.rows.isEmpty())
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
    fun knowsWhetherPreviousPeriodHasEntries() = modelTest(today = "2026-10-17") { setup ->
        setup.save(Entry.Kind.expense, amount = 980, on = date("2026-10-05"))
        setup.save(Entry.Kind.income, amount = 3000, on = date("2026-09-03"))
        val model = setup.observedModel()

        val hasPreviousNow = model.output.hasPreviousEntries
        val comparison = model.output.comparisonText
        model.state.move(count = -1)

        assertTrue(hasPreviousNow)
        assertEquals("前の月の同じ日までより ¥980 多い", comparison)
        assertFalse(model.output.hasPreviousEntries)
        assertEquals("比べる記録がまだありません", model.output.comparisonText)
    }

    @Test
    fun leavesOutCategoriesMissingFromList() = modelTest(today = "2026-10-17") { setup ->
        val known = setup.save(Entry.Kind.expense, amount = 500, on = date("2026-10-12"))
        val list = setup.database.entryList()
        val unknown = known.copy(id = Identifier(), categoryId = Identifier(), amount = 300)
        val day = EntryDay(date = known.date, entries = listOf(known, unknown))

        val model = ReviewModel(
            parts = setup.parts(entryList = flowOf(list.copy(days = listOf(day)))),
            today = setup.today,
            round = ObservationRound(),
        )

        setup.scope.launch { model.observe() }
        ModelWait.until { model.input.list != null }

        assertEquals(800L, model.output.total)
        assertEquals(listOf(500L), model.output.rows.map { it.amount })
        assertEquals(listOf<String?>("100%"), model.output.rows.map { it.percent })
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
        assertEquals(listOf("75%", "25%"), rows.map { it.percent })
        assertEquals(listOf(daily.id.toString(), food.id.toString()), rows.map { it.key })
    }

    @Test
    fun showsNoRowsWithoutTotal() = modelTest(today = "2026-10-17") { setup ->
        setup.save(Entry.Kind.expense, amount = 500, on = date("2026-10-12"))
        val model = setup.observedModel()

        model.setKind(ReviewKind.income)

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
        model.setScale(ReviewPeriod.Scale.year)
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
        model.setScale(ReviewPeriod.Scale.week)
        model.saveSelection()
        val sunday = model.output.title

        setup.database.setSetting(key = SettingKey.weekStart, to = Weekday.monday)
        setup.scope.launch { model.observe() }
        ModelWait.until { model.input.weekStart == Weekday.monday }

        assertEquals("10/11〜10/17", sunday)
        assertEquals("10/12〜10/18", model.output.title)
    }

    @Test
    fun movesOnlyUpToCurrentPeriod() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.reviewModel()

        model.state.move(count = 1)
        val current = model.output.period.range.start
        val canMoveAtCurrent = model.output.canMoveForward
        model.state.move(count = -2)
        val earlier = model.output.period.range.start
        val canMoveFromEarlier = model.output.canMoveForward
        model.state.move(count = 3)
        val skipped = model.output.period.range.start
        model.setScale(ReviewPeriod.Scale.year)

        assertEquals("2026-10-01", current.toString())
        assertFalse(canMoveAtCurrent)
        assertEquals("2026-08-01", earlier.toString())
        assertTrue(canMoveFromEarlier)
        assertEquals("2026-08-01", skipped.toString())
        assertEquals("2026-01-01", model.output.period.range.start.toString())
        assertFalse(model.output.canMoveForward)
    }

    @Test
    fun movesForwardUpToCurrentPeriod() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.reviewModel()

        model.state.move(count = -2)
        model.state.move(count = 2)

        assertEquals("2026-10-01", model.output.period.range.start.toString())
        assertEquals(0, model.state.offset)
    }

    @Test
    fun remembersSelection() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.reviewModel()

        model.setScale(ReviewPeriod.Scale.week)
        model.setKind(ReviewKind.income)
        model.saveSelection()
        val reopened = setup.reviewModel()
        reopened.loadSelection()

        assertEquals(ReviewPeriod.Scale.week, reopened.input.scale)
        assertEquals(ReviewKind.income, reopened.input.kind)
    }

    @Test
    fun startsWithMonthAndExpenseWithoutSelection() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.reviewModel()

        model.loadSelection()

        assertEquals(ReviewPeriod.Scale.month, model.input.scale)
        assertEquals(ReviewKind.expense, model.input.kind)
    }

    @Test
    fun startsWithBalanceWhenBalanceWasSaved() = modelTest(today = "2026-10-17") { setup ->
        setup.database.setSetting(
            key = SettingKey.reviewKind,
            to = ReviewKind.balance,
        )
        val model = setup.reviewModel()

        model.loadSelection()
        model.setScale(ReviewPeriod.Scale.year)
        model.saveSelection()

        assertEquals(ReviewKind.balance, model.input.kind)
        assertEquals(ReviewKind.balance, setup.database.setting(SettingKey.reviewKind))
    }

    @Test
    fun remembersBalance() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.reviewModel()

        model.setKind(ReviewKind.balance)
        model.saveSelection()
        val reopened = setup.reviewModel()
        reopened.loadSelection()

        assertEquals(ReviewKind.balance, reopened.input.kind)
    }

    @Test
    fun comparesIncomeAndExpenseForBalance() = modelTest(today = "2026-10-17") { setup ->
        setup.save(Entry.Kind.expense, amount = 3000, on = date("2026-10-05"))
        setup.save(Entry.Kind.income, amount = 12000, on = date("2026-10-10"))
        setup.save(Entry.Kind.expense, amount = 9000, on = date("2026-09-10"))
        val model = setup.observedModel()
        val hidden = model.output.balanceBars

        model.setKind(ReviewKind.balance)
        val bars = model.output.balanceBars

        assertTrue(hidden.isEmpty())
        assertEquals(listOf("収入", "支出"), bars.map { it.title })
        assertEquals(listOf(Entry.Kind.income, Entry.Kind.expense), bars.map { it.type })
        assertEquals(listOf(12000L, 3000L), bars.map { it.amount })
        assertEquals(listOf(1.0, 0.25), bars.map { it.ratio })
        assertEquals(9000L, model.output.total)
        assertTrue(model.output.rows.isEmpty())
    }

    @Test
    fun showsEmptyBalanceBarsWithoutEntries() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.observedModel()

        model.setKind(ReviewKind.balance)

        assertEquals(listOf(0L, 0L), model.output.balanceBars.map { it.amount })
        assertEquals(listOf(0.0, 0.0), model.output.balanceBars.map { it.ratio })
        assertEquals(0L, model.output.total)
    }

    @Test
    fun scalesBalanceBarsToLargerExpense() = modelTest(today = "2026-10-17") { setup ->
        setup.save(Entry.Kind.expense, amount = 8000, on = date("2026-10-05"))
        setup.save(Entry.Kind.income, amount = 2000, on = date("2026-10-10"))
        val model = setup.observedModel()

        model.setKind(ReviewKind.balance)

        assertEquals(listOf(0.25, 1.0), model.output.balanceBars.map { it.ratio })
        assertEquals(-6000L, model.output.total)
    }

    @Test
    fun keepsSelectionOnlyAfterSaving() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.reviewModel()

        model.setScale(ReviewPeriod.Scale.year)
        model.setKind(ReviewKind.income)
        val scaleBefore = setup.database.setting(SettingKey.reviewScale)
        val kindBefore = setup.database.setting(SettingKey.reviewKind)
        model.saveSelection()

        assertEquals(ReviewPeriod.Scale.month, scaleBefore)
        assertEquals(ReviewKind.expense, kindBefore)
        assertEquals(ReviewPeriod.Scale.year, setup.database.setting(SettingKey.reviewScale))
        assertEquals(ReviewKind.income, setup.database.setting(SettingKey.reviewKind))
    }

    @Test
    fun readsSavedSelectionWhenObserving() = modelTest(today = "2026-10-17") { setup ->
        setup.database.setSetting(key = SettingKey.reviewScale, to = ReviewPeriod.Scale.year)
        setup.database.setSetting(key = SettingKey.reviewKind, to = ReviewKind.income)
        val model = setup.observedModel()

        assertEquals(ReviewPeriod.Scale.year, model.input.scale)
        assertEquals(ReviewKind.income, model.input.kind)
        assertEquals("2026年", model.output.title)
    }

    private fun ModelTestSetup.reviewModel() = ReviewModel(
        parts = parts,
        today = today,
        round = ObservationRound(),
    )

    private suspend fun ModelTestSetup.observedModel(): ReviewModel {
        val model = reviewModel()

        scope.launch { model.observe() }
        ModelWait.until { model.input.list != null }

        return model
    }
}

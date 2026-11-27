package com.yossibank.kakeibot.featuremodels.screens.settings.budgets

import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.featuremodels.screens.settings.budgets.BudgetListModel.Target
import com.yossibank.kakeibot.featuremodels.shared.model.EditFlow
import com.yossibank.kakeibot.featuremodels.support.ModelTestSetup
import com.yossibank.kakeibot.featuremodels.support.ModelWait
import com.yossibank.kakeibot.featuremodels.support.failingEntryList
import com.yossibank.kakeibot.featuremodels.support.modelTest
import com.yossibank.kakeibot.store.queries.methods.budgets
import com.yossibank.kakeibot.store.queries.methods.setting
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.budgetCarryoverFrom
import com.yossibank.kakeibot.store.records.settingkeys.monthStartDay
import com.yossibank.kakeibot.store.writes.methods.setBudget
import com.yossibank.kakeibot.store.writes.methods.setSetting
import kotlinx.coroutines.launch
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class BudgetListModelTest {
    @Test
    fun setsTotalAndCategoryBudgetsFromPeriodMonth() = modelTest(today = "2026-10-12") { setup ->
        setup.database.setSetting(
            key = SettingKey.monthStartDay,
            to = checkNotNull(MonthStartDay.of(day = 10)),
        )
        val model = setup.observedModel()
        ModelWait.until { model.output.month.toString() == "2026-11" }
        val food = model.output.categories.first()

        model.startEditing(Target.Total)
        val emptyTitle = model.flow.output.saveTitle
        model.press(1, 2, 0, 0, 0, 0)
        val title = model.flow.output.saveTitle
        model.flow.save()
        ModelWait.until { model.output.totalAmount != null }

        model.startEditing(Target.Category(food))
        model.press(3, 0, 0, 0, 0)
        model.flow.save()
        ModelWait.until { model.output.amount(food.id) != null }
        val budgets = setup.database.budgets()

        assertEquals("金額を入れてください", emptyTitle)
        assertEquals("11月からこの額にする", title)
        assertEquals(120_000, model.output.totalAmount)
        assertEquals(30000, model.output.amount(food.id))
        assertEquals(30000, model.output.categoriesTotal)
        assertNull(model.state.presented.editing)
        assertTrue(budgets.all { it.fromMonth == model.output.month })
    }

    @Test
    fun clearsAndRestoresBudget() = modelTest(today = "2026-10-12") { setup ->
        setup.database.setBudget(amount = 50000, categoryId = null, from = setup.today.yearMonth)
        val model = setup.observedModel()
        ModelWait.until { model.output.totalAmount != null }

        model.startEditing(Target.Total)
        val current = model.state.submodels.calculator.amount
        val cleared = assertNotNull(model.clear())
        val shown = model.state.notices.cleared.current
        ModelWait.until { model.output.totalAmount == null }

        model.restore(cleared)
        ModelWait.until { model.output.totalAmount != null }

        assertEquals(50000, current)
        assertEquals(cleared, shown)
        assertEquals("月全体の予算", cleared.target.title)
        assertEquals(50000, model.output.totalAmount)
        assertEquals(1, setup.database.budgets().size)
    }

    @Test
    fun restoresBudgetCarriedFromEarlierMonth() = modelTest(today = "2026-10-12") { setup ->
        val earlier = setup.today.yearMonth.adding(months = -2)
        setup.database.setBudget(amount = 30000, categoryId = null, from = earlier)
        val model = setup.observedModel()
        ModelWait.until { model.output.totalAmount != null }

        model.startEditing(Target.Total)
        val cleared = assertNotNull(model.clear())
        ModelWait.until { model.output.totalAmount == null }
        model.restore(cleared)
        ModelWait.until { model.output.totalAmount != null }

        assertEquals(30000, model.output.totalAmount)
        assertEquals(listOf(earlier), setup.database.budgets().map { it.fromMonth })
    }

    @Test
    fun savesWithDoneAndShowsSpending() = modelTest(today = "2026-10-12") { setup ->
        setup.save(Entry.Kind.expense, amount = 9000, daysAgo = 0)
        setup.save(Entry.Kind.income, amount = 50000, daysAgo = 0)
        val model = setup.observedModel()
        val food = model.output.categories.first()

        model.startEditing(Target.Category(food))
        model.press(1, 0, 0, 0, 0)
        model.finishEditing()
        ModelWait.until { model.output.amount(food.id) != null }
        val usage = assertNotNull(model.output.usage(food.id))

        model.startEditing(Target.Total)
        model.finishEditing()

        assertEquals(10000, model.output.amount(food.id))
        assertEquals(9000L, usage.spent)
        assertEquals(1000L, usage.remaining)
        assertTrue(usage.isNearLimit)
        assertEquals(9000L, model.output.spent(null))
        assertNull(model.output.totalAmount)
        assertNull(model.state.presented.editing)
    }

    @Test
    fun detectsChangedAmountWhileEditing() = modelTest(today = "2026-10-12") { setup ->
        setup.database.setBudget(amount = 50000, categoryId = null, from = setup.today.yearMonth)
        val model = setup.observedModel()
        ModelWait.until { model.output.totalAmount != null }
        val closed = model.output.isChanged

        model.startEditing(Target.Total)
        val opened = model.output.isChanged
        model.press(1)
        val changed = model.output.isChanged
        model.state.cancelEditing()

        assertFalse(closed)
        assertFalse(opened)
        assertTrue(changed)
        assertFalse(model.output.isChanged)
        assertEquals(50000, model.output.totalAmount)
    }

    @Test
    fun asksBeforeDiscardingChangedAmount() = modelTest(today = "2026-10-12") { setup ->
        setup.database.setBudget(amount = 50000, categoryId = null, from = setup.today.yearMonth)
        val model = setup.observedModel()
        ModelWait.until { model.output.totalAmount != null }

        model.startEditing(Target.Total)
        model.flow.close()
        val unchanged = model.flow.state.outcome.value?.closes
        val closedOnce = model.flow.state.outcome.count
        model.state.cancelEditing()

        model.startEditing(Target.Total)
        model.press(1)
        model.flow.close()
        val isAsking = model.flow.state.presented.prompt.isShowing(EditFlow.Prompt.discard)
        val kept = model.state.presented.editing

        model.flow.discard()

        assertEquals(true, unchanged)
        assertEquals(1, closedOnce)
        assertTrue(isAsking)
        assertEquals(Target.Total, kept)
        assertNull(model.flow.state.presented.prompt.current)
        assertEquals(2, model.flow.state.outcome.count)
    }

    @Test
    fun turnsCarryoverOnFromPeriodMonthAndOff() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.observedModel()
        val initial = model.output.isCarryoverOn

        model.setCarryover(isOn = true)
        val stored = setup.database.setting(SettingKey.budgetCarryoverFrom)
        ModelWait.until { model.output.isCarryoverOn }

        model.setCarryover(isOn = false)
        val cleared = setup.database.setting(SettingKey.budgetCarryoverFrom)
        ModelWait.until { !model.output.isCarryoverOn }

        assertFalse(initial)
        assertEquals(model.output.month, stored)
        assertNull(cleared)
    }

    @Test
    fun carriesOnlyTotalBudgetRemainingIntoTotalUsage() = modelTest(today = "2026-10-12") { setup ->
        setup.carryover()
        val model = setup.observedModel()
        ModelWait.until { model.output.carryover != 0L }
        val food = model.output.categories.first()

        assertEquals(70000L, model.output.carryover)
        assertEquals(70000L, model.output.usage(null)?.carryover)
        assertEquals(0L, model.output.usage(food.id)?.carryover)
    }

    @Test
    fun resetsCarryoverAndRestoresStart() = modelTest(today = "2026-10-12") { setup ->
        setup.carryover()
        val model = setup.observedModel()
        ModelWait.until { model.output.carryover != 0L }
        val start = model.input.overview?.carryoverFrom

        val previous = assertNotNull(model.resetCarryover())
        val shown = model.state.notices.resetFrom.current
        ModelWait.until { model.output.carryover == 0L }
        val resetStart = setup.database.setting(SettingKey.budgetCarryoverFrom)

        model.restoreCarryover(from = previous)
        ModelWait.until { model.output.carryover != 0L }

        assertEquals(start, previous)
        assertEquals(previous, shown)
        assertEquals(model.output.month, resetStart)
        assertEquals(70000L, model.output.carryover)
        assertEquals(start, setup.database.setting(SettingKey.budgetCarryoverFrom))
    }

    @Test
    fun keepsCarryoverWhenResetIsNotNeeded() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.observedModel()
        val off = model.resetCarryover()

        model.setCarryover(isOn = true)
        ModelWait.until { model.output.isCarryoverOn }
        val zero = model.resetCarryover()

        assertNull(off)
        assertNull(zero)
        assertNull(model.state.notices.resetFrom.current)
        assertEquals(0L, model.output.carryover)
        assertEquals(model.output.month, setup.database.setting(SettingKey.budgetCarryoverFrom))
    }

    @Test
    fun suggestsLastMonthAverageAndRecurring() = modelTest(today = "2026-10-12") { setup ->
        setup.save(Entry.Kind.expense, amount = 48200, daysAgo = 20)
        setup.save(Entry.Kind.expense, amount = 40000, daysAgo = 50)
        setup.save(Entry.Kind.expense, amount = 45150, daysAgo = 80)
        setup.save(Entry.Kind.income, amount = 300_000, daysAgo = 20)
        setup.saveRecurring(amount = 82800, day = 25)
        val model = setup.observedModel()
        ModelWait.until { model.output.recurringExpense != 0L }
        val closed = model.output.suggestions

        model.startEditing(Target.Total)
        val total = model.output.suggestions
        val food = model.output.categories.first()
        model.startEditing(Target.Category(food))
        val category = model.output.suggestions
        model.state.choose(category.last())

        assertTrue(closed.isEmpty())
        assertEquals(listOf("先月", "3 か月の平均", "固定費"), total.map { it.title })
        assertEquals(listOf(48200, 44500, 82800), total.map { it.amount })
        assertEquals(listOf(48200, 44500), category.map { it.amount })
        assertEquals(44500, model.state.submodels.calculator.amount)
    }

    @Test
    fun suggestsOnlyRecurringWithoutRecords() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.observedModel()

        model.startEditing(Target.Total)
        val empty = model.output.suggestions
        setup.saveRecurring(amount = 82800, day = 25)
        ModelWait.until { model.output.recurringExpense != 0L }
        val total = model.output.suggestions
        val food = model.output.categories.first()
        model.startEditing(Target.Category(food))

        assertTrue(empty.isEmpty())
        assertEquals(listOf("固定費"), total.map { it.title })
        assertEquals(listOf(82800), total.map { it.amount })
        assertTrue(model.output.suggestions.isEmpty())
    }

    @Test
    fun averagesOnlyMonthsSinceFirstRecord() = modelTest(today = "2026-10-12") { setup ->
        setup.save(Entry.Kind.expense, amount = 30000, daysAgo = 20)
        setup.save(Entry.Kind.expense, amount = 20001, daysAgo = 50)
        val model = setup.observedModel()

        model.startEditing(Target.Total)

        assertEquals(listOf(30000, 25100), model.output.suggestions.map { it.amount })
    }

    @Test
    fun skipsAverageUntilTwoMonthsAreRecorded() = modelTest(today = "2026-10-12") { setup ->
        setup.save(Entry.Kind.expense, amount = 30000, daysAgo = 20)
        val model = setup.observedModel()

        model.startEditing(Target.Total)

        assertEquals(listOf("先月"), model.output.suggestions.map { it.title })
    }

    @Test
    fun tellsWhenBudgetsCannotBeRead() = modelTest(today = "2026-10-12") { setup ->
        val model = BudgetListModel(
            parts = setup.parts(entryList = failingEntryList),
            today = setup.today,
        )

        setup.scope.launch { model.observe() }
        ModelWait.until { model.state.notices.error.message.isNotEmpty() }

        assertEquals("予算を読めませんでした", model.state.notices.error.message)
        assertNull(model.input.overview)
    }

    @Test
    fun keepsNoticeWhenEditingStarts() = modelTest(today = "2026-10-12") { setup ->
        val model = BudgetListModel(
            parts = setup.parts(entryList = failingEntryList),
            today = setup.today,
        )

        setup.scope.launch { model.observe() }
        ModelWait.until { model.state.notices.error.message.isNotEmpty() }
        model.startEditing(Target.Total)

        assertEquals("予算を読めませんでした", model.state.notices.error.message)
    }

    private fun BudgetListModel.press(vararg digits: Int) {
        for (digit in digits) {
            state.press(AmountCalculator.Key.Digit(digit))
        }
    }

    private suspend fun ModelTestSetup.carryover() {
        val food = options().expenseCategories.first()
        val earlier = today.yearMonth.adding(months = -3)
        val start = today.yearMonth.adding(months = -2)

        database.setBudget(amount = 50000, categoryId = null, from = earlier)
        database.setBudget(amount = 99999, categoryId = food.id, from = earlier)
        save(Entry.Kind.expense, amount = 10000, daysAgo = 50)
        save(Entry.Kind.expense, amount = 20000, daysAgo = 20)
        database.setSetting(key = SettingKey.budgetCarryoverFrom, to = start)
    }

    private suspend fun ModelTestSetup.observedModel(): BudgetListModel {
        val model = BudgetListModel(
            parts = parts,
            today = today,
        )

        scope.launch { model.observe() }
        ModelWait.until { model.input.overview != null && model.input.categoryList != null }

        return model
    }
}

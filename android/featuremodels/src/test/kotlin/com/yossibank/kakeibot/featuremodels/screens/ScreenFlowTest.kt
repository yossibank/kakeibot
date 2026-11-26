package com.yossibank.kakeibot.featuremodels.screens

import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.featuremodels.screens.entry.model.select
import com.yossibank.kakeibot.featuremodels.screens.settings.budgets.BudgetListModel
import com.yossibank.kakeibot.featuremodels.screens.settings.menu.SettingsMenuModel
import com.yossibank.kakeibot.featuremodels.screens.settings.recurring.RecurringEditModel
import com.yossibank.kakeibot.featuremodels.support.ModelTestSetup.Companion.date
import com.yossibank.kakeibot.featuremodels.support.ModelWait
import com.yossibank.kakeibot.featuremodels.support.modelTest
import com.yossibank.kakeibot.store.queries.methods.entryList
import com.yossibank.kakeibot.store.records.settingkeys.monthStartDay
import kotlinx.coroutines.launch
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ScreenFlowTest {
    @Test
    fun plannedEntryCountsInBalancesWhenItsDayComes() = modelTest(today = "2026-10-15") { setup ->
        val bank = setup.options().wallets[1].id
        val tomorrow = setup.today.adding(days = 1)
        val tabs = setup.openTabs()
        setup.record(5000, type = Entry.Kind.income, on = tomorrow, wallet = bank)
        ModelWait.until { tabs.amounts.all { it == listOf(5000) } }

        assertEquals(0L, tabs.assets.output.total)
        assertEquals(5000L, tabs.overview.monthIncome)

        setup.passDay(to = tomorrow, tabs = tabs)
        ModelWait.until { tabs.isOn(tomorrow) }

        assertEquals(5000L, tabs.assets.output.total)
        assertEquals(5000L, tabs.balance(of = bank))
        assertEquals(true, tabs.home.output.recentRows.first().detail?.contains("今日"))
    }

    @Test
    fun entryRecordedAfterTheDayChangedLandsOnTheNewDay() = modelTest(
        today = "2026-10-15",
    ) { setup ->
        val tomorrow = setup.today.adding(days = 1)
        val tabs = setup.openTabs()
        setup.record(1200)
        setup.passDay(to = tomorrow, tabs = tabs)

        setup.record(300, today = tomorrow)
        ModelWait.until { tabs.amounts.all { it.size == 2 } && tabs.isOn(tomorrow) }
        val recorded = setup.database.entryList().entries.first { it.amount == 300 }

        assertEquals(tomorrow, recorded.date)
        assertEquals(300L, tabs.overview.todayExpense)
        assertEquals(1200L, tabs.overview.yesterdayExpense)
        assertEquals(listOf(tomorrow, setup.today), tabs.records.output.days.map { it.date })
        assertEquals(-1500L, tabs.assets.output.total)
    }

    @Test
    fun transferWithFeeMovesBalancesUntilDeletedAndUndone() = modelTest(
        today = "2026-10-15",
    ) { setup ->
        val wallets = setup.options().wallets
        val tabs = setup.openTabs()
        val entry = setup.entryModel()
        entry.select(type = Entry.Kind.transfer)
        entry.type(10000)
        entry.state.setFee(220)

        val isSaved = entry.save()
        ModelWait.until { tabs.amounts.all { it.size == 2 } }
        val transfer = setup.database.entryList().entries.first { it.toWalletId != null }

        assertTrue(isSaved)
        assertEquals(-10220L, tabs.balance(of = wallets[0].id))
        assertEquals(10000L, tabs.balance(of = wallets[1].id))
        assertEquals(-220L, tabs.assets.output.total)
        assertEquals(220L, tabs.overview.monthExpense)
        assertEquals(220L, tabs.records.output.expenseTotal)
        assertEquals(220L, tabs.review.output.total)

        val isDeleted = setup.entryModel(editing = transfer.id).delete()
        ModelWait.until { tabs.amounts.all { it.isEmpty() } }

        assertTrue(isDeleted)
        assertEquals(0L, tabs.balance(of = wallets[0].id))
        assertEquals(0L, tabs.balance(of = wallets[1].id))
        assertEquals(0L, tabs.overview.monthExpense)
    }

    @Test
    fun cardExpenseWaitsForItsBillAndIsPaidWhenTheDayComes() = modelTest(
        today = "2026-10-15",
    ) { setup ->
        val bank = setup.options().wallets[1].id
        val card = setup.addWallet(kind = Wallet.Kind.card, name = "カード")
        setup.addCardBill(card = card.id, paidFrom = bank)
        val payDay = date("2026-11-26")
        val tabs = setup.openTabs()
        val entry = setup.entryModel()
        entry.type(3000)
        entry.select(wallet = card)

        val isSaved = entry.save()
        ModelWait.until { tabs.amounts.all { 3000 in it } }

        assertTrue(isSaved)
        assertEquals(-3000L, tabs.balance(of = card.id))
        assertEquals(0L, tabs.balance(of = bank))
        assertEquals(0L, tabs.assets.output.holdings.onHand)
        assertEquals(-3000L, tabs.assets.output.total)
        assertEquals(3000L, tabs.overview.monthExpense)

        setup.passDay(to = payDay, tabs = tabs)
        ModelWait.until { tabs.isOn(payDay) && tabs.balance(of = card.id) == 0L }
        val bill = setup.database.entryList().entries.first { it.toWalletId == card.id }

        assertEquals(-3000L, tabs.balance(of = bank))
        assertEquals(-3000L, tabs.assets.output.holdings.onHand)
        assertEquals(-3000L, tabs.assets.output.total)
        assertEquals(Entry.Kind.transfer, bill.type)
        assertEquals(3000, bill.amount)
        assertEquals(26, bill.date.day)
        assertEquals(0L, tabs.overview.monthExpense)
    }

    @Test
    fun recurringSavedInSettingsFillsTabsAndIsRecordedOnItsNextDay() = modelTest(
        today = "2026-10-15",
    ) { setup ->
        val cash = setup.options().wallets[0].id
        val nextDay = date("2026-11-10")
        val tabs = setup.openTabs()
        val editor = RecurringEditModel(
            parts = setup.parts,
            today = setup.today,
        )
        editor.load()

        for (digit in listOf(7, 8, 0, 0, 0)) {
            editor.state.press(AmountCalculator.Key.Digit(digit))
        }

        editor.state.update { copy(memo = "家賃", day = 10, startDate = date("2026-09-01")) }
        val saved = editor.flow.save()
        ModelWait.until { tabs.amounts.all { it == listOf(78000, 78000) } }

        assertNotNull(saved)
        assertEquals(listOf("2026-10-10"), tabs.records.output.days.map { it.date.toString() })
        assertEquals(78000L, tabs.review.output.total)
        assertEquals(-156_000L, tabs.balance(of = cash))

        setup.passDay(to = nextDay, tabs = tabs)
        ModelWait.until { tabs.isOn(nextDay) && tabs.amounts.all { it.size == 3 } }

        assertEquals(-234_000L, tabs.balance(of = cash))
        assertEquals(listOf(nextDay), tabs.records.output.days.map { it.date })
        assertEquals(78000L, tabs.review.output.total)
    }

    @Test
    fun changedMonthStartDayMovesThePeriodOfEveryTab() = modelTest(today = "2026-10-15") { setup ->
        val early = date("2026-10-05")
        val late = date("2026-10-12")
        val start = date("2026-10-10")
        val startDay = checkNotNull(MonthStartDay.of(day = 10))
        val tabs = setup.openTabs()
        setup.record(500, on = early)
        setup.record(1200, on = late)
        ModelWait.until { tabs.amounts.all { it.size == 2 } }
        val settings = SettingsMenuModel(parts = setup.parts)

        assertEquals(1700L, tabs.overview.monthExpense)
        assertEquals(1700L, tabs.records.output.expenseTotal)
        assertEquals(1700L, tabs.review.output.total)

        settings.choose(monthStartDay = startDay)
        ModelWait.until {
            tabs.overview.monthStartDay == startDay &&
                tabs.records.input.monthStartDay == startDay &&
                tabs.review.input.monthStartDay == startDay
        }

        assertEquals(start, tabs.overview.period.start)
        assertEquals(1200L, tabs.overview.monthExpense)
        assertEquals(start, tabs.records.output.period.start)
        assertNull(tabs.records.state.month)
        assertEquals(listOf(late), tabs.records.output.days.map { it.date })
        assertEquals(1200L, tabs.records.output.expenseTotal)
        assertEquals(start, tabs.review.output.period.range.start)
        assertEquals(1200L, tabs.review.output.total)

        tabs.records.move(months = -1)
        tabs.review.state.move(count = -1)

        assertEquals(listOf(early), tabs.records.output.days.map { it.date })
        assertEquals(500L, tabs.review.output.total)
    }

    @Test
    fun budgetSetInSettingsFollowsNewEntriesOnHome() = modelTest(today = "2026-10-15") { setup ->
        val tabs = setup.openTabs()
        setup.record(1200)
        ModelWait.until { tabs.amounts.all { it == listOf(1200) } }
        val settings = BudgetListModel(
            parts = setup.parts,
            today = setup.today,
        )
        setup.scope.launch { settings.observe() }
        ModelWait.until { settings.input.overview != null && settings.input.categoryList != null }
        settings.startEditing(BudgetListModel.Target.Total)

        for (digit in listOf(3, 0, 0, 0, 0)) {
            settings.state.press(AmountCalculator.Key.Digit(digit))
        }

        settings.flow.save()
        ModelWait.until { tabs.home.output.usage != null }

        assertEquals(28800L, tabs.home.output.usage?.remaining)
        assertEquals("今月の支出", tabs.home.output.middleTitle)

        setup.record(800)
        ModelWait.until { tabs.home.output.usage?.remaining == 28000L }

        ModelWait.until { settings.output.totalAmount != null }
        settings.startEditing(BudgetListModel.Target.Total)
        val cleared = assertNotNull(settings.clear())
        ModelWait.until { tabs.home.output.usage == null }

        assertEquals("昨日の支出", tabs.home.output.middleTitle)

        settings.restore(cleared)
        ModelWait.until { tabs.home.output.usage != null }

        assertEquals(28000L, tabs.home.output.usage?.remaining)
    }

    @Test
    fun editedEntryMovesToAnotherMonthInEveryTab() = modelTest(today = "2026-10-15") { setup ->
        val cash = setup.options().wallets[0].id
        val lastMonth = date("2026-09-20")
        val tabs = setup.openTabs()
        setup.record(1200)
        val recorded = setup.database.entryList().entries.first()
        val editor = setup.entryModel(editing = recorded.id)

        editor.state.press(AmountCalculator.Key.Delete)
        editor.state.select(date = lastMonth)
        val isSaved = editor.save()
        ModelWait.until { tabs.amounts.all { it == listOf(120) } }

        assertTrue(isSaved)
        assertEquals(0L, tabs.overview.monthExpense)
        assertEquals(listOf(120), tabs.home.output.recentRows.map { it.amount })
        assertTrue(tabs.records.output.days.isEmpty())
        assertEquals(0L, tabs.review.output.total)
        assertEquals(-120L, tabs.balance(of = cash))

        tabs.records.move(months = -1)
        tabs.review.state.move(count = -1)

        assertEquals(listOf(lastMonth), tabs.records.output.days.map { it.date })
        assertEquals(120L, tabs.records.output.expenseTotal)
        assertEquals(120L, tabs.review.output.total)
    }

    @Test
    fun deletedEntryLeavesEveryTabUntilUndone() = modelTest(today = "2026-10-15") { setup ->
        val tabs = setup.openTabs()
        setup.record(1200, memo = "ランチ")
        val recorded = setup.database.entryList().entries.first()
        val editor = setup.entryModel(editing = recorded.id)
        ModelWait.until { tabs.amounts.all { it == listOf(1200) } }
        val memos = tabs.home.output.recentRows.map { it.memo }

        val isDeleted = editor.delete()
        ModelWait.until { tabs.amounts.all { it.isEmpty() } }

        assertEquals(listOf<String?>("ランチ"), memos)
        assertTrue(isDeleted)
        assertTrue(tabs.home.output.showsNoRecords)
        assertEquals(0L, tabs.overview.todayExpense)
        assertTrue(tabs.records.output.days.isEmpty())
        assertEquals(0L, tabs.review.output.total)
        assertEquals(0L, tabs.assets.output.total)
    }
}

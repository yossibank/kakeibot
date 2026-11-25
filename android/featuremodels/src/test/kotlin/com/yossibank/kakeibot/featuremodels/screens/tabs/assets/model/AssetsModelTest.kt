package com.yossibank.kakeibot.featuremodels.screens.tabs.assets.model

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.featuremodels.shared.model.ObservationRound
import com.yossibank.kakeibot.featuremodels.support.ModelTestSetup
import com.yossibank.kakeibot.featuremodels.support.ModelTestSetup.Companion.date
import com.yossibank.kakeibot.featuremodels.support.ModelWait
import com.yossibank.kakeibot.featuremodels.support.failingEntryList
import com.yossibank.kakeibot.featuremodels.support.failingFirst
import com.yossibank.kakeibot.featuremodels.support.modelTest
import com.yossibank.kakeibot.store.queries.methods.entryListUpdates
import com.yossibank.kakeibot.store.writes.methods.setHidden
import com.yossibank.kakeibot.store.writes.types.WalletTable
import kotlinx.coroutines.launch
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class AssetsModelTest {
    @Test
    fun showsNoticeWhenListFails() = modelTest(today = "2026-10-17") { setup ->
        val model = AssetsModel(
            entryList = failingEntryList,
            today = setup.today,
            round = ObservationRound(),
        )

        setup.scope.launch { model.observe() }
        ModelWait.until { model.state.task.message.isNotEmpty() }

        assertEquals("残高を読めませんでした", model.state.task.message)
        assertTrue(model.output.rows.isEmpty())
    }

    @Test
    fun marksListFailureUntilRetried() = modelTest(today = "2026-10-17") { setup ->
        val model = AssetsModel(
            entryList = setup.database.entryListUpdates().failingFirst(times = 4),
            today = setup.today,
            round = ObservationRound(),
        )

        setup.scope.launch { model.observe() }
        ModelWait.until { model.state.isListFailed }
        val message = model.state.task.message
        val list = model.input.list
        model.retry()
        ModelWait.until { model.input.list != null }

        assertEquals("残高を読めませんでした", message)
        assertNull(list)
        assertFalse(model.state.isListFailed)
    }

    @Test
    fun showsNoRowsBeforeListArrives() = modelTest(today = "2026-10-17") { setup ->
        val model = AssetsModel(
            entryList = setup.database.entryListUpdates(),
            today = setup.today,
            round = ObservationRound(),
        )

        assertTrue(model.output.rows.isEmpty())
        assertEquals(0L, model.output.netWorth)
    }

    @Test
    fun sumsBalancesByWallet() = modelTest(today = "2026-10-17") { setup ->
        val options = setup.options()
        val cash = options.wallets[0].id
        val bank = options.wallets[1].id
        setup.save(Entry.Kind.income, amount = 250_000, on = date("2026-09-25"), walletId = bank)
        setup.save(Entry.Kind.expense, amount = 980, on = date("2026-10-01"), walletId = cash)
        setup.save(
            Entry.Kind.transfer,
            amount = 10000,
            on = date("2026-10-02"),
            walletId = bank,
            toWalletId = cash,
        )
        val model = setup.observedModel()

        assertEquals(listOf("財布", "銀行"), model.output.rows.map { it.name })
        assertEquals(listOf(9020L, 240_000L), model.output.rows.map { it.balance })
        assertEquals(249_020L, model.output.netWorth)
        assertEquals(249_020L, model.output.total)
    }

    @Test
    fun separatesDebtsFromAssets() = modelTest(today = "2026-10-17") { setup ->
        val card = setup.addWallet(kind = Wallet.Kind.card, name = "カード")
        val loan = setup.addWallet(kind = Wallet.Kind.loan, name = "奨学金", initialBalance = -100_000)
        setup.save(Entry.Kind.income, amount = 50000, on = date("2026-10-01"))
        setup.save(Entry.Kind.expense, amount = 3000, on = date("2026-10-05"), walletId = card.id)
        val model = setup.observedModel()

        assertEquals(listOf("財布", "銀行"), model.output.assets.map { it.name })
        assertEquals(listOf(card.id, loan.id), model.output.debts.map { it.id })
        assertEquals(listOf(-3000L, -100_000L), model.output.debts.map { it.balance })
        assertEquals(47000L, model.output.total)
        assertEquals(-53000L, model.output.netWorth)
    }

    @Test
    fun countsCardsInTotal() = modelTest(today = "2026-10-17") { setup ->
        val card = setup.addWallet(kind = Wallet.Kind.card, name = "カード")
        setup.save(Entry.Kind.income, amount = 50000, on = date("2026-10-01"))
        setup.save(Entry.Kind.expense, amount = 3000, on = date("2026-10-05"), walletId = card.id)
        val model = setup.observedModel()

        assertEquals(50000L, model.output.holdings.onHand)
        assertEquals(3000L, model.output.holdings.unpaid)
        assertEquals(47000L, model.output.total)
    }

    @Test
    fun describesBreakdownOfTotal() = modelTest(today = "2026-10-17") { setup ->
        val card = setup.addWallet(kind = Wallet.Kind.card, name = "カード")
        setup.save(Entry.Kind.income, amount = 50000, on = date("2026-10-01"))
        val model = setup.observedModel()
        val plain = model.output.breakdownText

        setup.save(Entry.Kind.expense, amount = 3000, on = date("2026-10-05"), walletId = card.id)
        ModelWait.until { model.output.holdings.unpaid == 3000L }
        val unpaid = model.output.breakdownText

        setup.save(Entry.Kind.income, amount = 4000, on = date("2026-10-06"), walletId = card.id)
        ModelWait.until { model.output.holdings.refund == 1000L }

        assertEquals("手持ち ¥50,000", plain)
        assertEquals("手持ち ¥50,000・未払い ¥3,000", unpaid)
        assertEquals("手持ち ¥50,000・返ってくる額 ¥1,000", model.output.breakdownText)
    }

    @Test
    fun leavesOutHiddenWallets() = modelTest(today = "2026-10-17") { setup ->
        val card = setup.addWallet(kind = Wallet.Kind.card, name = "カード")
        setup.database.setHidden(WalletTable, id = card.id, isHidden = true, at = setup.now)
        val model = setup.observedModel()

        assertEquals(listOf("財布", "銀行"), model.output.rows.map { it.name })
    }

    @Test
    fun followsNewEntries() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.observedModel()

        setup.save(Entry.Kind.income, amount = 1000, on = date("2026-10-10"))
        ModelWait.until { model.output.netWorth == 1000L }

        assertEquals(1000L, model.output.rows.first().balance)
    }

    @Test
    fun leavesOutFutureEntriesFromBalances() = modelTest(today = "2026-10-17") { setup ->
        setup.save(Entry.Kind.income, amount = 1000, on = date("2026-10-10"))
        setup.save(Entry.Kind.expense, amount = 400, on = date("2026-10-20"))
        val model = setup.observedModel()

        assertEquals(1000L, model.output.rows.first().balance)
        assertEquals(1000L, model.output.netWorth)
        assertEquals(1000L, model.output.total)
    }

    @Test
    fun countsEntriesOfToday() = modelTest(today = "2026-10-17") { setup ->
        setup.save(Entry.Kind.income, amount = 1000, on = date("2026-10-16"))
        setup.save(Entry.Kind.expense, amount = 400, on = date("2026-10-17"))
        setup.save(Entry.Kind.expense, amount = 50, on = date("2026-10-18"))
        val model = setup.observedModel()

        assertEquals(600L, model.output.rows.first().balance)
    }

    @Test
    fun leavesOutFutureTransfersFromBothWallets() = modelTest(today = "2026-10-17") { setup ->
        val options = setup.options()
        val cash = options.wallets[0].id
        val bank = options.wallets[1].id
        setup.save(Entry.Kind.income, amount = 5000, on = date("2026-10-10"), walletId = bank)
        setup.save(
            Entry.Kind.transfer,
            amount = 300,
            on = date("2026-10-18"),
            walletId = bank,
            toWalletId = cash,
        )
        val model = setup.observedModel()

        assertEquals(listOf(0L, 5000L), model.output.rows.map { it.balance })
    }

    @Test
    fun leavesOutFutureCardUsageFromDebts() = modelTest(today = "2026-10-17") { setup ->
        val card = setup.addWallet(kind = Wallet.Kind.card, name = "カード")
        setup.save(Entry.Kind.expense, amount = 3000, on = date("2026-10-05"), walletId = card.id)
        setup.save(Entry.Kind.expense, amount = 800, on = date("2026-10-25"), walletId = card.id)
        val model = setup.observedModel()

        assertEquals(listOf(-3000L), model.output.debts.map { it.balance })
        assertEquals(-3000L, model.output.netWorth)
    }

    @Test
    fun countsEntriesWhenTodayReachesThem() = modelTest(today = "2026-10-17") { setup ->
        setup.save(Entry.Kind.income, amount = 1000, on = date("2026-10-10"))
        setup.save(Entry.Kind.expense, amount = 400, on = date("2026-10-20"))
        val model = setup.observedModel()
        val before = model.output.netWorth

        model.setToday(date("2026-10-19"))
        val dayBefore = model.output.netWorth
        model.setToday(date("2026-10-20"))

        assertEquals(1000L, before)
        assertEquals(1000L, dayBefore)
        assertEquals(600L, model.output.netWorth)
        assertEquals(600L, model.output.rows.first().balance)
        assertEquals(date("2026-10-20"), model.input.today)
    }

    @Test
    fun leavesOutEntriesWhenTodayGoesBack() = modelTest(today = "2026-10-17") { setup ->
        setup.save(Entry.Kind.income, amount = 1000, on = date("2026-10-10"))
        setup.save(Entry.Kind.expense, amount = 400, on = date("2026-10-15"))
        val model = setup.observedModel()

        model.setToday(date("2026-10-14"))

        assertEquals(1000L, model.output.netWorth)
    }

    private suspend fun ModelTestSetup.observedModel(): AssetsModel {
        val model = AssetsModel(
            entryList = database.entryListUpdates(),
            today = today,
            round = ObservationRound(),
        )

        scope.launch { model.observe() }
        ModelWait.until { model.output.rows.isNotEmpty() }

        return model
    }
}

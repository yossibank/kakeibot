package com.yossibank.kakeibot.features.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.features.support.ModelTestSetup.Companion.date
import com.yossibank.kakeibot.features.support.ModelTestSetup.Companion.month
import com.yossibank.kakeibot.features.support.modelTest
import com.yossibank.kakeibot.store.queries.methods.entryList
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class EntryModelTransferTest {
    @Test
    fun startsWithTwoDifferentWallets() = modelTest(today = "2026-10-12") { setup ->
        val wallets = setup.options().wallets
        val model = setup.transferModel()

        assertEquals(wallets[0].id, model.state.form.walletId)
        assertEquals(wallets[1].id, model.state.form.toWalletId)
        assertNull(model.state.form.categoryId)
        assertEquals(EntryModel.Field.Transfer, model.state.field)
        assertEquals("財布 → 銀行", model.output.routeText)
    }

    @Test
    fun savesSwappedTransfer() = modelTest(today = "2026-10-12") { setup ->
        val wallets = setup.options().wallets
        val model = setup.transferModel()
        model.press(3, 0, 0, 0, 0)

        model.state.swapWallets()
        val saved = model.save()
        val entry = setup.database.entryList().entries.first()

        assertTrue(saved)
        assertEquals(Entry.Kind.transfer, entry.type)
        assertEquals(wallets[1].id, entry.walletId)
        assertEquals(wallets[0].id, entry.toWalletId)
        assertNull(entry.categoryId)
    }

    @Test
    fun keepsFirstCategoryWhenComingBackFromTransfer() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        val category = model.state.form.categoryId

        model.select(type = Entry.Kind.transfer)
        val transferCategory = model.state.form.categoryId
        model.select(type = Entry.Kind.expense)

        assertNull(transferCategory)
        assertEquals(category, model.state.form.categoryId)
        assertNull(model.state.form.toWalletId)
    }

    @Test
    fun showsBalancesAndMissingDestination() = modelTest(today = "2026-10-12") { setup ->
        val bank = setup.options().wallets[1]
        setup.save(Entry.Kind.income, amount = 5000, on = date("2026-10-01"), walletId = bank.id)
        val model = setup.transferModel()
        model.press(5)

        val balance = model.output.balance(of = bank)
        model.state.update { copy(toWalletId = null) }
        model.save()

        assertEquals(5000L, balance)
        assertEquals("振替先を選んでください", model.state.task.message)
    }

    @Test
    fun leavesOutFutureEntriesFromBalance() = modelTest(today = "2026-10-12") { setup ->
        val cash = setup.options().wallets[0]
        setup.save(Entry.Kind.income, amount = 1000, on = setup.today, walletId = cash.id)
        setup.save(
            Entry.Kind.expense,
            amount = 400,
            on = setup.today.adding(days = 3),
            walletId = cash.id,
        )
        val model = setup.loadedModel()

        assertEquals(1000L, model.output.balance(of = cash))
    }

    @Test
    fun flagsAmountOverSourceBalance() = modelTest(today = "2026-10-12") { setup ->
        setup.save(Entry.Kind.income, amount = 3000, on = date("2026-10-01"))
        val model = setup.transferModel()

        model.press(3, 0, 0, 0)
        val atBalance = model.output.isOverSourceBalance
        model.press(1)

        assertFalse(atBalance)
        assertTrue(model.output.isOverSourceBalance)
    }

    @Test
    fun waitsForAmountBeforeWarningOverNegativeBalance() =
        modelTest(today = "2026-10-12") { setup ->
            val card = setup.addWallet(
                kind = Wallet.Kind.card,
                name = "カード",
                initialBalance = -5000,
            )
            val model = setup.transferModel()

            model.state.select(card)
            val empty = model.output.isOverSourceBalance
            model.press(1)

            assertFalse(empty)
            assertTrue(model.output.isOverSourceBalance)
        }

    @Test
    fun paysOffLoanAtOnce() = modelTest(today = "2026-10-12") { setup ->
        val bank = setup.options().wallets[1]
        val loan = setup.addWallet(kind = Wallet.Kind.loan, name = "奨学金", initialBalance = -100_000)
        val model = setup.transferModel()
        model.state.select(bank)
        model.state.selectDestination(loan)

        val remaining = model.output.loanRemaining
        model.press(3, 0, 0, 0, 0)
        val current = model.output.currentLine(of = loan)
        val partial = model.output.afterLine(of = loan, isSource = false)
        model.payOffLoan()

        assertEquals(100_000L, remaining)
        assertEquals("今の残り", current?.title)
        assertEquals(100_000L, current?.amount)
        assertEquals("返済後", partial?.title)
        assertEquals(70000L, partial?.amount)
        assertEquals(100_000, model.output.amount)
        assertEquals(0L, model.output.afterLine(of = loan, isSource = false)?.amount)
    }

    @Test
    fun reportsSameWallet() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.transferModel()
        model.press(5)
        model.state.update { copy(toWalletId = walletId) }

        assertFalse(model.save())
        assertEquals("振替元と振替先を別にしてください", model.state.task.message)
    }

    @Test
    fun listsRecentTransfersOnce() = modelTest(today = "2026-10-12") { setup ->
        val wallets = setup.options().wallets
        val cash = wallets[0].id
        val bank = wallets[1].id
        setup.saveTransfer(5000, from = bank, to = cash)
        setup.saveTransfer(3000, from = cash, to = bank)
        setup.saveTransfer(5000, from = bank, to = cash)
        setup.saveTransfer(1000, from = bank, to = cash)
        val model = setup.transferModel()

        val amounts = model.output.recentTransfers.map { it.amount }
        model.applyTransfer(model.output.recentTransfers.last())

        assertEquals(listOf(1000, 5000, 3000), amounts)
        assertEquals(cash, model.state.form.walletId)
        assertEquals(bank, model.state.form.toWalletId)
        assertEquals(3000, model.output.amount)
    }

    @Test
    fun ordersFrequentRoutesByCount() = modelTest(today = "2026-10-12") { setup ->
        val wallets = setup.options().wallets
        val cash = wallets[0].id
        val bank = wallets[1].id
        setup.saveTransfer(3000, from = cash, to = bank)
        setup.saveTransfer(5000, from = bank, to = cash)
        setup.saveTransfer(1000, from = bank, to = cash)
        val model = setup.transferModel()

        val routes = model.output.frequentRoutes
        model.state.applyRoute(routes.last())

        assertEquals(listOf(bank, cash), routes.map { it.walletId })
        assertEquals(cash, model.state.form.walletId)
        assertEquals(bank, model.state.form.toWalletId)
    }

    @Test
    fun savesFeeTypedOnKeypad() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.transferModel()
        model.press(5, 0, 0, 0)

        model.state.focus(EntryModel.Field.Fee)
        model.press(1, 1, 0)
        val saved = model.save()
        val entries = setup.database.entryList().entries

        assertTrue(saved)
        assertEquals(110, model.output.fee)
        assertEquals(5000, model.output.amount)
        assertEquals(listOf(110), entries.filter { it.transferId != null }.map { it.amount })
    }

    @Test
    fun keepsFeeOnlyForTransfer() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()

        model.state.focus(EntryModel.Field.Fee)
        val field = model.state.field
        model.state.setFee(110)

        assertEquals(EntryModel.Field.Amount, field)
        assertEquals(0, model.output.fee)
    }

    @Test
    fun putsUsedFeesFirst() = modelTest(today = "2026-10-12") { setup ->
        val wallets = setup.options().wallets
        setup.saveTransfer(5000, from = wallets[1].id, to = wallets[0].id, fee = 330)
        val model = setup.transferModel()

        assertEquals(330, model.output.feeChoices.first())
        assertEquals(330, model.output.fee(of = model.output.recentTransfers.first()))
    }

    @Test
    fun countsFeeInSourceBalance() = modelTest(today = "2026-10-12") { setup ->
        setup.save(Entry.Kind.income, amount = 5000, on = date("2026-10-01"))
        val model = setup.transferModel()

        model.press(4, 9, 0, 0)
        val withoutFee = model.output.isOverSourceBalance
        model.state.setFee(110)

        assertFalse(withoutFee)
        assertTrue(model.output.isOverSourceBalance)
    }

    @Test
    fun opensTransferFromFee() = modelTest(today = "2026-10-12") { setup ->
        val wallets = setup.options().wallets
        setup.saveTransfer(5000, from = wallets[1].id, to = wallets[0].id, fee = 110)
        val fee = setup.database.entryList().entries.first { it.transferId != null }
        val model = setup.loadedModel(editing = fee.id)

        assertEquals(Entry.Kind.transfer, model.state.form.type)
        assertEquals(5000, model.output.amount)
        assertEquals(110, model.output.fee)
        assertEquals(fee.transferId, model.input.editingId)
    }

    @Test
    fun clearsBillMonthWhenWalletOrDateChanges() = modelTest(today = "2026-10-12") { setup ->
        val wallets = setup.options().wallets
        val model = setup.loadedModel()

        model.state.update { copy(billMonth = month("2026-11")) }
        model.state.select(wallets[1])
        val afterWallet = model.state.form.billMonth
        model.state.update { copy(billMonth = month("2026-11")) }
        model.state.select(date = date("2026-10-13"))

        assertNull(afterWallet)
        assertNull(model.state.form.billMonth)
    }
}

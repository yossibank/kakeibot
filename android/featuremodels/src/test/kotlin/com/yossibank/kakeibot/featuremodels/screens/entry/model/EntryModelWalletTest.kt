package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.featuremodels.support.modelTest
import com.yossibank.kakeibot.store.writes.methods.setHidden
import com.yossibank.kakeibot.store.writes.types.WalletTable
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class EntryModelWalletTest {
    @Test
    fun startsWithFirstWalletWithoutEntries() = modelTest(today = "2026-10-12") { setup ->
        val options = setup.options()
        val model = setup.loadedModel()

        assertEquals(options.wallets[0].id, model.state.fields.form.walletId)
    }

    @Test
    fun startsWithLastRecordedWallet() = modelTest(today = "2026-10-12") { setup ->
        val options = setup.options()
        val categories = options.expenseCategories
        val wallets = options.wallets
        setup.save(Entry.Kind.expense, amount = 500, on = setup.today, walletId = wallets[0].id)
        setup.save(Entry.Kind.expense, amount = 500, on = setup.today, walletId = wallets[1].id)
        val model = setup.loadedModel()

        val first = model.state.fields.form.walletId
        model.state.select(categories[1])

        assertEquals(wallets[1].id, first)
        assertEquals(wallets[1].id, model.state.fields.form.walletId)
    }

    @Test
    fun startsEachTypeWithItsLastWallet() = modelTest(today = "2026-10-12") { setup ->
        val wallets = setup.options().wallets
        setup.save(Entry.Kind.expense, amount = 500, on = setup.today, walletId = wallets[1].id)
        val model = setup.loadedModel()

        model.select(type = Entry.Kind.income)
        val income = model.state.fields.form.walletId
        model.select(type = Entry.Kind.expense)

        assertEquals(wallets[0].id, income)
        assertEquals(wallets[1].id, model.state.fields.form.walletId)
        assertFalse(model.output.isChanged)
    }

    @Test
    fun keepsWalletWhenSwitchingToTransfer() = modelTest(today = "2026-10-12") { setup ->
        val wallets = setup.options().wallets
        setup.save(Entry.Kind.expense, amount = 500, on = setup.today, walletId = wallets[1].id)
        val model = setup.loadedModel()

        model.select(type = Entry.Kind.transfer)

        assertEquals(wallets[1].id, model.state.fields.form.walletId)
        assertEquals(wallets[0].id, model.state.fields.form.toWalletId)
    }

    @Test
    fun keepsWalletOfTouchedEntryWhenTypeChanges() = modelTest(today = "2026-10-12") { setup ->
        val wallets = setup.options().wallets
        setup.save(Entry.Kind.expense, amount = 500, on = setup.today, walletId = wallets[1].id)
        val model = setup.loadedModel()
        model.press(5)

        model.select(type = Entry.Kind.income)

        assertEquals(wallets[1].id, model.state.fields.form.walletId)
        assertTrue(model.output.isChanged)
    }

    @Test
    fun keepsChosenWallet() = modelTest(today = "2026-10-12") { setup ->
        val options = setup.options()
        val categories = options.expenseCategories
        val wallets = options.wallets
        setup.save(
            Entry.Kind.expense,
            amount = 500,
            on = setup.today,
            categoryId = categories[1].id,
            walletId = wallets[0].id,
        )
        val model = setup.loadedModel()

        model.state.select(categories[1])
        model.select(wallet = wallets[1])
        model.state.select(categories[2])
        model.select(type = Entry.Kind.income)

        assertEquals(wallets[1].id, model.state.fields.form.walletId)
    }

    @Test
    fun startsNextEntryFollowingTypeAgain() = modelTest(today = "2026-10-12") { setup ->
        val wallets = setup.options().wallets
        val model = setup.loadedModel()
        model.select(wallet = wallets[1])
        model.press(5)
        model.save()

        model.startNext()
        model.select(type = Entry.Kind.income)
        val income = model.state.fields.form.walletId
        model.select(type = Entry.Kind.expense)

        assertEquals(wallets[0].id, income)
        assertEquals(wallets[1].id, model.state.fields.form.walletId)
    }

    @Test
    fun startsWithWalletOfLatestSaveNotLatestDate() = modelTest(today = "2026-10-12") { setup ->
        val wallets = setup.options().wallets
        setup.save(Entry.Kind.expense, amount = 500, on = setup.today, walletId = wallets[0].id)
        setup.save(
            Entry.Kind.expense,
            amount = 500,
            on = setup.today.adding(days = -5),
            walletId = wallets[1].id,
        )
        val model = setup.loadedModel()

        assertEquals(wallets[1].id, model.state.fields.form.walletId)
    }

    @Test
    fun ignoresIncomeAndTransferForExpenseWallet() = modelTest(today = "2026-10-12") { setup ->
        val wallets = setup.options().wallets
        setup.save(Entry.Kind.income, amount = 500, on = setup.today, walletId = wallets[1].id)
        setup.saveTransfer(amount = 300, from = wallets[1].id, to = wallets[0].id, fee = 110)
        val model = setup.loadedModel()

        assertEquals(wallets[0].id, model.state.fields.form.walletId)
    }

    @Test
    fun startsWithFirstWalletWhenLastOneIsHidden() = modelTest(today = "2026-10-12") { setup ->
        val wallets = setup.options().wallets
        setup.save(Entry.Kind.expense, amount = 500, on = setup.today, walletId = wallets[1].id)
        setup.database.setHidden(WalletTable, id = wallets[1].id, isHidden = true, at = setup.now)
        val model = setup.loadedModel()

        assertEquals(wallets[0].id, model.state.fields.form.walletId)
    }

    @Test
    fun keepsWalletOfEditedEntry() = modelTest(today = "2026-10-12") { setup ->
        val wallets = setup.options().wallets
        val entry = setup.save(
            Entry.Kind.expense,
            amount = 500,
            on = setup.today,
            walletId = wallets[0].id,
        )
        setup.save(Entry.Kind.expense, amount = 500, on = setup.today, walletId = wallets[1].id)
        val model = setup.loadedModel(editing = entry.id)

        val loaded = model.state.fields.form.walletId
        model.select(type = Entry.Kind.income)
        model.select(type = Entry.Kind.expense)

        assertEquals(wallets[0].id, loaded)
        assertEquals(wallets[0].id, model.state.fields.form.walletId)
    }
}

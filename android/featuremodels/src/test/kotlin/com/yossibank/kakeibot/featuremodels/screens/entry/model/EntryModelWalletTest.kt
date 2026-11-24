package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.featuremodels.support.modelTest
import com.yossibank.kakeibot.store.writes.methods.setHidden
import com.yossibank.kakeibot.store.writes.types.WalletTable
import org.junit.Test
import kotlin.test.assertEquals

class EntryModelWalletTest {
    @Test
    fun startsWithFirstWalletWithoutEntries() = modelTest(today = "2026-10-12") { setup ->
        val options = setup.options()
        val model = setup.loadedModel()

        assertEquals(options.wallets[0].id, model.state.form.walletId)
    }

    @Test
    fun startsWithLastRecordedWallet() = modelTest(today = "2026-10-12") { setup ->
        val options = setup.options()
        val categories = options.expenseCategories
        val wallets = options.wallets
        setup.save(Entry.Kind.expense, amount = 500, on = setup.today, walletId = wallets[0].id)
        setup.save(Entry.Kind.expense, amount = 500, on = setup.today, walletId = wallets[1].id)
        val model = setup.loadedModel()

        val first = model.state.form.walletId
        model.state.select(categories[1])

        assertEquals(wallets[1].id, first)
        assertEquals(wallets[1].id, model.state.form.walletId)
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

        assertEquals(wallets[1].id, model.state.form.walletId)
    }

    @Test
    fun ignoresIncomeAndTransferForExpenseWallet() = modelTest(today = "2026-10-12") { setup ->
        val wallets = setup.options().wallets
        setup.save(Entry.Kind.income, amount = 500, on = setup.today, walletId = wallets[1].id)
        setup.saveTransfer(amount = 300, from = wallets[1].id, to = wallets[0].id, fee = 110)
        val model = setup.loadedModel()

        assertEquals(wallets[0].id, model.state.form.walletId)
    }

    @Test
    fun startsWithFirstWalletWhenLastOneIsHidden() = modelTest(today = "2026-10-12") { setup ->
        val wallets = setup.options().wallets
        setup.save(Entry.Kind.expense, amount = 500, on = setup.today, walletId = wallets[1].id)
        setup.database.setHidden(WalletTable, id = wallets[1].id, isHidden = true, at = setup.now)
        val model = setup.loadedModel()

        assertEquals(wallets[0].id, model.state.form.walletId)
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

        assertEquals(wallets[0].id, model.state.form.walletId)
    }
}

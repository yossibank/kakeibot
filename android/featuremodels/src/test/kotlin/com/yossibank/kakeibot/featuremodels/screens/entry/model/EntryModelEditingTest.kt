package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.featuremodels.shared.model.ErrorNotice
import com.yossibank.kakeibot.featuremodels.shared.model.ModelTask
import com.yossibank.kakeibot.featuremodels.support.ModelTestSetup.Companion.month
import com.yossibank.kakeibot.featuremodels.support.modelTest
import com.yossibank.kakeibot.store.queries.methods.entry
import com.yossibank.kakeibot.store.queries.methods.entryList
import com.yossibank.kakeibot.store.writes.methods.setHidden
import com.yossibank.kakeibot.store.writes.types.EntryCategoryTable
import com.yossibank.kakeibot.store.writes.types.WalletTable
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class EntryModelEditingTest {
    @Test
    fun labelsSaveButtonByState() = modelTest(today = "2026-10-12") { setup ->
        val entry = setup.save(Entry.Kind.expense, amount = 800, on = setup.today)
        val model = setup.loadedModel()
        val editing = setup.loadedModel(editing = entry.id)

        val empty = model.output.saveTitle
        val opensKeypad = model.output.opensKeypadOnSave
        model.press(9, 8, 0)

        assertEquals("金額を入れてください", empty)
        assertTrue(opensKeypad)
        assertEquals("記録する", model.output.saveTitle)
        assertTrue(model.output.canSave)
        assertFalse(model.output.opensKeypadOnSave)
        assertEquals("変更を保存", editing.output.saveTitle)
    }

    @Test
    fun keepsHiddenWalletsWhenEditing() = modelTest(today = "2026-10-12") { setup ->
        val wallets = setup.options().wallets
        val cash = wallets[0].id
        val entry = setup.save(
            Entry.Kind.expense,
            amount = 800,
            on = setup.today,
            walletId = cash,
            billMonth = month("2026-11"),
        )
        setup.database.setHidden(WalletTable, id = cash, isHidden = true, at = setup.now)

        val model = setup.loadedModel(editing = entry.id)

        assertEquals(cash, model.state.fields.form.walletId)
        assertEquals(entry.billMonth, model.state.fields.form.billMonth)
        assertNotNull(model.output.wallet(of = cash))
        assertNotNull(model.output.wallet(of = wallets[1].id))
        assertEquals(cash, model.output.wallet?.id)
    }

    @Test
    fun keepsHiddenTransferWalletsWhenEditing() = modelTest(today = "2026-10-12") { setup ->
        val wallets = setup.options().wallets
        val cash = wallets[0].id
        val bank = wallets[1].id
        setup.saveTransfer(3000, from = cash, to = bank)
        val transfer = setup.database.entryList().entries.first()
        setup.database.setHidden(WalletTable, id = bank, isHidden = true, at = setup.now)

        val model = setup.loadedModel(editing = transfer.id)

        assertEquals(cash, model.state.fields.form.walletId)
        assertEquals(bank, model.state.fields.form.toWalletId)
        assertNotNull(model.output.wallet(of = bank))
        assertEquals("財布 → 銀行", model.output.routeText)
    }

    @Test
    fun keepsHiddenCategoryWhenEditing() = modelTest(today = "2026-10-12") { setup ->
        val salary = setup.options().incomeCategories[0].id
        val entry = setup.save(Entry.Kind.income, amount = 3000, on = setup.today)
        setup.database.setHidden(EntryCategoryTable, id = salary, isHidden = true, at = setup.now)

        val model = setup.loadedModel(editing = entry.id)

        assertEquals(salary, model.state.fields.form.categoryId)
        assertEquals(salary, model.output.category?.id)
        assertFalse(model.output.isChanged)
    }

    @Test
    fun restoresHiddenCategoryAfterSwitchingType() = modelTest(today = "2026-10-12") { setup ->
        val salary = setup.options().incomeCategories[0].id
        val entry = setup.save(Entry.Kind.income, amount = 3000, on = setup.today)
        setup.database.setHidden(EntryCategoryTable, id = salary, isHidden = true, at = setup.now)
        val model = setup.loadedModel(editing = entry.id)

        model.select(type = Entry.Kind.expense)
        model.select(type = Entry.Kind.income)

        assertEquals(salary, model.state.fields.form.categoryId)
    }

    @Test
    fun leavesHiddenChoicesOutOfNewEntry() = modelTest(today = "2026-10-12") { setup ->
        val options = setup.options()
        val cash = options.wallets[0].id
        val salary = options.incomeCategories[0].id
        setup.save(Entry.Kind.income, amount = 3000, on = setup.today)
        setup.database.setHidden(WalletTable, id = cash, isHidden = true, at = setup.now)
        setup.database.setHidden(EntryCategoryTable, id = salary, isHidden = true, at = setup.now)
        val model = setup.loadedModel()

        model.select(type = Entry.Kind.income)

        assertNull(model.output.wallet(of = cash))
        assertFalse(model.output.categories.any { it.id == salary })
    }

    @Test
    fun fitsCategoryToSharedWalletWhenEditing() = modelTest(today = "2026-10-12") { setup ->
        val options = setup.options()
        val own = options.expenseCategories[0]
        val bank = options.wallets[1].id
        val copies = setup.startSharing(bank)
        val entry = setup.save(
            Entry.Kind.expense,
            amount = 800,
            on = setup.today,
            categoryId = own.id,
            walletId = bank,
        )

        val model = setup.loadedModel(editing = entry.id)

        assertEquals(bank, model.state.fields.form.walletId)
        assertEquals(copies[0].id, model.state.fields.form.categoryId)
        assertEquals(own.name, model.output.category?.name)
        assertEquals(bank, model.output.category?.walletId)
        assertFalse(model.output.isChanged)
    }

    @Test
    fun reportsMissingEntryWhenLoading() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel(editing = Identifier())

        val saved = model.save()

        assertEquals("記録が見つかりませんでした", model.state.notices.error.message)
        assertTrue(model.output.isEditing)
        assertNull(model.state.fields.form.walletId)
        assertNull(model.state.fields.form.categoryId)
        assertFalse(model.output.isChanged)
        assertFalse(saved)
    }

    @Test
    fun leavesEditedTransferOutOfRecentTransfers() = modelTest(today = "2026-10-12") { setup ->
        val wallets = setup.options().wallets
        setup.saveTransfer(3000, from = wallets[0].id, to = wallets[1].id)
        setup.saveTransfer(1000, from = wallets[1].id, to = wallets[0].id)
        val edited = setup.database.entryList().entries.first { it.amount == 1000 }

        val model = setup.loadedModel(editing = edited.id)

        assertEquals(listOf(3000), model.output.recentTransfers.map { it.amount })
    }

    @Test
    fun dropsBillMonthWithoutBillChoices() = modelTest(today = "2026-10-12") { setup ->
        val entry = setup.save(
            Entry.Kind.expense,
            amount = 800,
            on = setup.today,
            billMonth = month("2026-11"),
        )
        val model = setup.loadedModel(editing = entry.id)
        val loaded = model.state.fields.form.billMonth

        val saved = model.save()

        assertEquals(month("2026-11"), loaded)
        assertTrue(saved)
        assertNull(setup.database.entry(entry.id)?.billMonth)
    }

    @Test
    fun keepsBillMonthOfCardWithBill() = modelTest(today = "2026-10-12") { setup ->
        val bank = setup.options().wallets[1].id
        val card = setup.addWallet(kind = Wallet.Kind.card, name = "カード")
        setup.addCardBill(card = card.id, paidFrom = bank)
        val entry = setup.save(
            Entry.Kind.expense,
            amount = 800,
            on = setup.today,
            walletId = card.id,
            billMonth = month("2026-11"),
        )
        val model = setup.loadedModel(editing = entry.id)

        val saved = model.save()
        model.select(type = Entry.Kind.transfer)

        assertTrue(saved)
        assertEquals(month("2026-11"), setup.database.entry(entry.id)?.billMonth)
        assertNotEquals(month("2026-11"), model.output.draft?.billMonth)
    }

    @Test
    fun recordsEditedEntryAgainAsNewEntry() = modelTest(today = "2026-10-12") { setup ->
        val entry = setup.save(Entry.Kind.expense, amount = 980, daysAgo = 3)
        val model = setup.loadedModel(editing = entry.id)
        model.state.update { copy(memo = "ランチ") }

        model.recordAgain()
        val isEditing = model.output.isEditing
        val message = model.state.notices.error.message
        val tone = model.state.notices.error.tone
        model.save()
        val entries = setup.database.entryList().entries
        val saved = entries.first { it.id != entry.id }
        val stored = setup.database.entry(entry.id)

        assertFalse(isEditing)
        assertEquals("同じ内容で新しい記録にしました", message)
        assertEquals(ErrorNotice.Tone.info, tone)
        assertEquals(980, saved.amount)
        assertEquals("ランチ", saved.memo)
        assertEquals(entry.categoryId, saved.categoryId)
        assertEquals(setup.today, saved.date)
        assertEquals(2, entries.size)
        assertEquals(entry.memo, stored?.memo)
    }
}

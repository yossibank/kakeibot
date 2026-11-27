package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryDraft
import com.yossibank.kakeibot.featuremodels.support.modelTest
import com.yossibank.kakeibot.store.writes.methods.saveEntry
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class EntryModelRecentTest {
    @Test
    fun appliesRecentEntry() = modelTest(today = "2026-10-12") { setup ->
        val saved = setup.save(Entry.Kind.expense, amount = 980, on = setup.today)
        val model = setup.loadedModel()

        model.applyRecent(saved)

        assertEquals(980, model.output.amount)
        assertEquals(saved.categoryId, model.state.fields.form.categoryId)
        assertEquals(saved.walletId, model.state.fields.form.walletId)
    }

    @Test
    fun appliesRecentTagOfOfferedCategory() = modelTest(today = "2026-10-12") { setup ->
        val category = setup.options().expenseCategories[1]
        val tag = setup.addTags(categoryId = category.id, names = listOf("買い置き")).first()
        val saved = setup.database.saveEntry(
            draft = EntryDraft(
                type = Entry.Kind.expense,
                amount = 980,
                date = setup.today,
                categoryId = category.id,
                tagId = tag.id,
                walletId = setup.options().wallets[0].id,
            ),
            at = setup.now,
        )
        val model = setup.loadedModel()

        model.applyRecent(saved)

        assertEquals(category.id, model.state.fields.form.categoryId)
        assertEquals(tag.id, model.state.fields.form.tagId)
    }

    @Test
    fun dropsRecentTagOutsideOfferedCategories() = modelTest(today = "2026-10-12") { setup ->
        val options = setup.options()
        val category = options.expenseCategories[1]
        val shared = options.wallets[1]
        val tag = setup.addTags(categoryId = category.id, names = listOf("買い置き")).first()
        setup.startSharing(shared.id)
        val saved = setup.database.saveEntry(
            draft = EntryDraft(
                type = Entry.Kind.expense,
                amount = 980,
                date = setup.today,
                categoryId = category.id,
                tagId = tag.id,
                walletId = shared.id,
            ),
            at = setup.now,
        )
        val model = setup.loadedModel()

        model.applyRecent(saved)

        assertEquals(shared.id, model.state.fields.form.walletId)
        assertEquals(shared.id, model.output.category?.walletId)
        assertNull(model.state.fields.form.tagId)
        assertEquals(980, model.output.amount)
    }

    @Test
    fun skipsRecentEntriesThatMatchTemplates() = modelTest(today = "2026-10-15") { setup ->
        val template = setup.saveTemplate(name = "ランチ", amount = 980)
        setup.save(
            Entry.Kind.expense,
            amount = 980,
            on = setup.today,
            memo = "社食",
            categoryId = template.categoryId,
            walletId = template.walletId,
        )
        setup.save(
            Entry.Kind.expense,
            amount = 220,
            on = setup.today,
            categoryId = template.categoryId,
            walletId = template.walletId,
        )

        val model = setup.loadedModel()

        assertEquals(listOf(220), model.output.recentEntries.map { it.amount })
    }

    @Test
    fun listsNoRecentEntriesForTransfers() = modelTest(today = "2026-10-12") { setup ->
        setup.save(Entry.Kind.expense, amount = 980, on = setup.today)

        val model = setup.transferModel()

        assertTrue(model.output.recentEntries.isEmpty())
    }

    @Test
    fun leavesEditedEntryOutOfRecentEntries() = modelTest(today = "2026-10-12") { setup ->
        setup.save(Entry.Kind.expense, amount = 980, on = setup.today)
        val edited = setup.save(Entry.Kind.expense, amount = 220, on = setup.today)

        val model = setup.loadedModel(editing = edited.id)

        assertEquals(listOf(980), model.output.recentEntries.map { it.amount })
    }
}

package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.featuremodels.support.modelTest
import com.yossibank.kakeibot.store.queries.methods.entryList
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class EntryModelTemplateTest {
    @Test
    fun showsTemplateIconWhileSharedWalletIsChosen() = modelTest(today = "2026-10-15") { setup ->
        val salary = setup.saveTemplate(name = "給料", amount = 300_000, type = Entry.Kind.income)
        val shared = setup.options().wallets[1]
        setup.startSharing(shared.id)
        val model = setup.loadedModel()
        model.select(type = Entry.Kind.income)

        model.select(wallet = shared)
        val category = model.output.category(of = salary.categoryId)

        assertEquals(shared.id, model.output.category?.walletId)
        assertNotNull(category?.let { model.output.icon(of = it.iconId) })
    }

    @Test
    fun dropsArchivedTagWhenApplyingTemplate() = modelTest(today = "2026-10-15") { setup ->
        val category = setup.options().expenseCategories[1]
        val tag = setup.addTags(categoryId = category.id, names = listOf("買い置き")).first()
        val stock = setup.saveTemplate(name = "買い置き", amount = 500, tagId = tag.id)
        setup.addTags(categoryId = category.id, names = emptyList())
        val model = setup.loadedModel()

        model.apply(stock)

        assertNull(model.state.form.tagId)
        assertEquals(stock.categoryId, model.state.form.categoryId)
        assertEquals(stock.id, model.state.form.templateId)
    }

    @Test
    fun dropsArchivedTagAndTemplateWhenRecordingAgain() = modelTest(today = "2026-10-15") { setup ->
        val category = setup.options().expenseCategories[1]
        val tag = setup.addTags(categoryId = category.id, names = listOf("買い置き")).first()
        val stock = setup.saveTemplate(name = "買い置き", amount = 500, tagId = tag.id)
        val first = setup.loadedModel()
        first.apply(stock)
        first.save()
        val entry = setup.database.entryList().entries.first()
        setup.addTags(categoryId = category.id, names = emptyList())
        val model = setup.loadedModel(editing = entry.id)

        model.recordAgain()
        model.save()
        val saved = setup.database.entryList().entries.first { it.id != entry.id }

        assertEquals(tag.id, entry.tagId)
        assertEquals(stock.id, entry.templateId)
        assertNull(saved.tagId)
        assertNull(saved.templateId)
    }

    @Test
    fun closesTemplateSheetAndReloadsAfterSaving() = modelTest(today = "2026-10-15") { setup ->
        val model = setup.loadedModel()
        model.state.presented.show(EntryModel.Presented.Template(model.output.newTemplateDraft()))
        val saved = setup.saveTemplate(name = "社食", amount = 500)

        model.receiveTemplate()

        assertNull(model.state.presented.current)
        assertTrue(model.input.allTemplates.any { it.id == saved.id })
    }
}

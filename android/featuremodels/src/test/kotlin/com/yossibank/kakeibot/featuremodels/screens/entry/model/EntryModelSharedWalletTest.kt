package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplateDraft
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.featuremodels.support.modelTest
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.writes.methods.saveTemplate
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class EntryModelSharedWalletTest {
    @Test
    fun offersSharedCategoriesForSharedWallet() = modelTest(today = "2026-10-12") { setup ->
        val wallets = setup.options().wallets
        val shared = wallets[1]
        setup.startSharing(shared.id)
        val model = setup.loadedModel()
        val own = model.output.category

        model.select(wallet = shared)
        val sharedCategory = model.output.category
        val walletIds = model.output.categories.map { it.walletId }.toSet()

        model.select(wallet = wallets[0])

        assertEquals(own?.name, sharedCategory?.name)
        assertEquals(shared.id, sharedCategory?.walletId)
        assertEquals(setOf(shared.id), walletIds)
        assertEquals(own, model.output.category)
    }

    @Test
    fun offersSharedCategoriesOfSelectedType() = modelTest(today = "2026-10-12") { setup ->
        val options = setup.options()
        val shared = options.wallets[1]
        setup.startSharing(shared.id)
        val model = setup.loadedModel()
        model.select(wallet = shared)

        model.select(type = Entry.Kind.income)
        val names = model.output.categories.map { it.name }

        assertEquals(options.incomeCategories.map { it.name }, names)
        assertEquals(shared.id, model.output.category?.walletId)
        assertEquals(options.incomeCategories[0].name, model.output.category?.name)
    }

    @Test
    fun movesTagToSameNameOfSharedCategory() = modelTest(today = "2026-10-12") { setup ->
        val options = setup.options()
        val shared = options.wallets[1]
        val food = options.expenseCategories[0]
        val copies = setup.startSharing(shared.id)
        val own = setup.addTags(categoryId = food.id, names = listOf("ランチ", "カフェ"))
        val lunch = setup.addSharedTag(category = copies[0], name = "ランチ")
        val model = setup.loadedModel()

        model.state.toggleTag(own[0].id)
        model.select(wallet = shared)
        val moved = model.state.form.tagId
        model.select(wallet = options.wallets[0])
        model.state.toggleTag(own[1].id)
        model.select(wallet = shared)

        assertEquals(lunch.id, moved)
        assertNull(model.state.form.tagId)
    }

    @Test
    fun fallsBackToFirstSharedCategoryWithoutSameName() = modelTest(today = "2026-10-12") { setup ->
        val options = setup.options()
        val shared = options.wallets[1]
        val copies = setup.startSharing(shared.id)
        val extra = options.expenseCategories[0].copy(
            id = Identifier(),
            name = "推し活",
            sortOrder = 99,
        )
        setup.database.categoryDao().insert(extra.record())
        val model = setup.loadedModel()
        model.state.select(extra)

        model.select(wallet = shared)

        assertEquals(copies[0].id, model.state.form.categoryId)
    }

    @Test
    fun keepsCategoryForWalletWithoutSharedCategories() = modelTest(today = "2026-10-12") { setup ->
        val options = setup.options()
        val daily = options.expenseCategories[1]
        setup.startSharing(options.wallets[1].id)
        val card = setup.addWallet(kind = Wallet.Kind.card, name = "カード")
        val model = setup.loadedModel()
        model.state.select(daily)

        model.select(wallet = card)

        assertEquals(daily.id, model.state.form.categoryId)
    }

    @Test
    fun startsWithSharedCategoryWhenLastWalletIsShared() =
        modelTest(today = "2026-10-12") { setup ->
            val options = setup.options()
            val shared = options.wallets[1]
            val copies = setup.startSharing(shared.id)
            setup.save(
                Entry.Kind.expense,
                amount = 500,
                on = setup.today,
                categoryId = copies[0].id,
                walletId = shared.id,
            )
            val model = setup.loadedModel()

            assertEquals(shared.id, model.state.form.walletId)
            assertEquals(copies[0].id, model.state.form.categoryId)
        }

    @Test
    fun fitsTemplateCategoryToSharedWallet() = modelTest(today = "2026-10-12") { setup ->
        val options = setup.options()
        val shared = options.wallets[1]
        val copies = setup.startSharing(shared.id)
        val daily = options.expenseCategories[1]
        val template = setup.database.saveTemplate(
            draft = EntryTemplateDraft(
                name = "日用品",
                type = Entry.Kind.expense,
                amount = null,
                categoryId = daily.id,
                walletId = shared.id,
            ),
            at = setup.now,
        )
        val model = setup.loadedModel()

        model.apply(template)

        assertEquals(shared.id, model.state.form.walletId)
        assertEquals(copies[1].id, model.state.form.categoryId)
        assertEquals(template.id, model.state.form.templateId)
    }
}

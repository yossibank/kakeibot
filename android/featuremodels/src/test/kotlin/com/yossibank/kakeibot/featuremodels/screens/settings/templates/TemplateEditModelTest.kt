package com.yossibank.kakeibot.featuremodels.screens.settings.templates

import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplateDraft
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenClock
import com.yossibank.kakeibot.featuremodels.support.ModelTestSetup
import com.yossibank.kakeibot.featuremodels.support.modelTest
import com.yossibank.kakeibot.store.queries.methods.templates
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class TemplateEditModelTest {
    @Test
    fun entersAmountWithKeypad() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.templateModel(type = Entry.Kind.income)

        model.state.press(AmountCalculator.Key.Digit(1))
        model.state.press(AmountCalculator.Key.DoubleZero)
        val typed = model.output.amount
        model.state.press(AmountCalculator.Key.Clear)

        assertEquals(100, typed)
        assertNull(model.output.amount)
        assertEquals("入金先", model.output.walletTitle)
    }

    @Test
    fun choosesFirstCategoryAndWalletOnLoad() = modelTest(today = "2026-10-17") { setup ->
        val options = setup.options()
        val model = setup.templateModel(type = Entry.Kind.income)

        model.load()

        assertEquals(options.incomeCategories.first().id, model.state.form.categoryId)
        assertEquals(options.wallets.first().id, model.state.form.walletId)
        assertEquals(options.incomeCategories, model.output.categories)
    }

    @Test
    fun savesNewTemplateWithDefaults() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.templateModel(type = Entry.Kind.expense)
        model.load()

        val refused = model.save()
        val refusal = model.state.task.message
        model.state.update { copy(name = "ランチ") }
        model.state.press(AmountCalculator.Key.Digit(9))
        model.state.press(AmountCalculator.Key.Digit(8))
        model.state.press(AmountCalculator.Key.Digit(0))
        val saved = model.save()
        val templates = setup.database.templates()

        assertNull(refused)
        assertEquals("名前を入れてください", refusal)
        assertEquals(980, saved?.amount)
        assertEquals(listOf("ランチ"), templates.map { it.name })
        assertEquals(model.state.form.categoryId, templates.first().categoryId)
        assertEquals("", model.state.task.message)
    }

    @Test
    fun namesMissingWalletByType() = modelTest(today = "2026-10-17") { setup ->
        val model = setup.templateModel(type = Entry.Kind.income)
        model.state.update { copy(name = "給料", categoryId = null, walletId = null) }

        model.save()
        val category = model.state.task.message
        model.load()
        model.state.update { copy(walletId = null) }
        model.save()

        assertEquals("カテゴリを選んでください", category)
        assertEquals("入金先を選んでください", model.state.task.message)
    }

    @Test
    fun clearsTagWhenCategoryChanges() = modelTest(today = "2026-10-17") { setup ->
        val options = setup.options()
        val food = options.expenseCategories[0]
        val daily = options.expenseCategories[1]
        val tags = setup.addTags(categoryId = food.id, names = listOf("ランチ", "おやつ"))
        val model = setup.templateModel(type = Entry.Kind.expense)
        model.load()

        model.state.select(food)
        val shown = model.output.tags.map { it.name }
        model.state.toggleTag(tags[0].id)
        val detail = model.output.detail
        model.state.select(daily)

        assertEquals(listOf("ランチ", "おやつ"), shown)
        assertEquals("${food.name}・ランチ・財布", detail)
        assertNull(model.state.form.tagId)
        assertTrue(model.output.tags.isEmpty())
    }

    @Test
    fun togglesTagOff() = modelTest(today = "2026-10-17") { setup ->
        val food = setup.options().expenseCategories[0]
        val tag = setup.addTags(categoryId = food.id, names = listOf("ランチ")).first()
        val model = setup.templateModel(type = Entry.Kind.expense)
        model.load()

        model.state.toggleTag(tag.id)
        val selected = model.output.tag
        model.state.toggleTag(tag.id)

        assertEquals(tag.id, selected?.id)
        assertNull(model.output.tag)
    }

    @Test
    fun keepsBillShiftOnlyForBilledCard() = modelTest(today = "2026-10-17") { setup ->
        val options = setup.options()
        val bank = options.wallets[1]
        val card = setup.addWallet(kind = Wallet.Kind.card, name = "カード")
        setup.addCardBill(card = card.id, paidFrom = bank.id)
        val model = setup.templateModel(type = Entry.Kind.expense)
        model.load()

        model.state.select(card)
        model.state.update { copy(billShift = 1) }
        val bill = model.output.billRecurring
        val shift = model.output.draft.billShift
        model.state.select(options.wallets[0])

        assertNotNull(bill)
        assertEquals(1, shift)
        assertEquals(0, model.state.form.billShift)
        assertNull(model.output.billRecurring)
        assertEquals(0, model.output.draft.billShift)
    }

    private fun ModelTestSetup.templateModel(type: Entry.Kind) = TemplateEditModel(
        database = database,
        clock = ScreenClock.fixed(now),
        draft = EntryTemplateDraft(
            name = "",
            type = type,
            amount = null,
            categoryId = null,
            walletId = null,
        ),
    )
}

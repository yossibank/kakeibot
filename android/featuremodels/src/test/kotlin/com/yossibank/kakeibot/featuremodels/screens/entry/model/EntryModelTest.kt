package com.yossibank.kakeibot.featuremodels.screens.entry.model

import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplateDraft
import com.yossibank.kakeibot.featuremodels.support.ModelTestSetup
import com.yossibank.kakeibot.featuremodels.support.ModelTestSetup.Companion.date
import com.yossibank.kakeibot.featuremodels.support.modelTest
import com.yossibank.kakeibot.store.queries.methods.entry
import com.yossibank.kakeibot.store.queries.methods.entryList
import com.yossibank.kakeibot.store.writes.methods.deleteEntry
import com.yossibank.kakeibot.store.writes.methods.saveTemplate
import kotlinx.coroutines.async
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class EntryModelTest {
    @Test
    fun buildsAmountFromKeys() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()

        model.press(1, 2)
        model.state.press(AmountCalculator.Key.DoubleZero)
        val typed = model.output.amount
        model.state.press(AmountCalculator.Key.Delete)

        assertEquals(1200, typed)
        assertEquals(120, model.output.amount)
    }

    @Test
    fun capsAmountAtNineDigits() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()

        model.press(9, 9, 9, 9, 9, 9, 9, 9, 9, 9)

        assertEquals(999_999_999, model.output.amount)
    }

    @Test
    fun describesExpressionAndTax() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()

        model.press(1, 2)
        model.state.press(AmountCalculator.Key.DoubleZero)
        model.state.press(AmountCalculator.Key.Operation(AmountCalculator.Operation.add))
        model.press(8)
        val expression = model.output.expressionText
        model.state.press(AmountCalculator.Key.Equals)
        val settled = model.output.expressionText
        model.state.press(AmountCalculator.Key.Tax(AmountCalculator.TaxRate.standard))

        assertEquals("1,200 ＋ 8", expression)
        assertNull(settled)
        assertEquals("1,208 の税込み 10%", model.output.expressionText)
        assertEquals(1328, model.output.amount)
    }

    @Test
    fun startsWithFirstCategoryAndWallet() = modelTest(today = "2026-10-12") { setup ->
        val options = setup.options()
        val model = setup.loadedModel()

        assertEquals(options.expenseCategories.first().id, model.state.form.categoryId)
        assertEquals(options.wallets.first().id, model.state.form.walletId)
        assertEquals(EntryModel.Field.Category, model.state.field)
        assertTrue(model.output.isBlank)
        assertTrue(model.output.showsRecent)
    }

    @Test
    fun picksFirstCategoryOfSelectedType() = modelTest(today = "2026-10-12") { setup ->
        val options = setup.options()
        val model = setup.loadedModel()

        model.select(type = Entry.Kind.income)

        assertEquals(options.incomeCategories.first().id, model.state.form.categoryId)
        assertEquals("入金先", model.output.walletTitle)
    }

    @Test
    fun remembersCategoryForEachType() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        val transit = model.output.categories.first { it.name == "交通" }
        model.state.select(transit)

        model.select(type = Entry.Kind.income)
        val incomeFirst = model.output.category?.name
        val bonus = model.output.categories.first { it.name == "臨時収入" }
        model.state.select(bonus)

        model.select(type = Entry.Kind.expense)
        val expenseBack = model.output.category?.name

        model.select(type = Entry.Kind.income)

        assertEquals("給料", incomeFirst)
        assertEquals("交通", expenseBack)
        assertEquals("臨時収入", model.output.category?.name)
    }

    @Test
    fun remembersCategoryAcrossTransfer() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        val transit = model.output.categories.first { it.name == "交通" }
        model.state.select(transit)

        model.select(type = Entry.Kind.transfer)
        val transferCategory = model.state.form.categoryId
        model.select(type = Entry.Kind.income)
        val incomeFirst = model.output.category?.name
        model.select(type = Entry.Kind.expense)

        assertNull(transferCategory)
        assertEquals("給料", incomeFirst)
        assertEquals("交通", model.output.category?.name)
    }

    @Test
    fun clearsTagWhenTypeChanges() = modelTest(today = "2026-10-12") { setup ->
        val food = setup.options().expenseCategories[0]
        val tag = setup.addTags(categoryId = food.id, names = listOf("ランチ")).first()
        val model = setup.loadedModel()
        model.state.toggleTag(tag.id)

        model.select(type = Entry.Kind.income)
        model.select(type = Entry.Kind.expense)

        assertEquals(food.id, model.state.form.categoryId)
        assertNull(model.state.form.tagId)
    }

    @Test
    fun savesNewEntry() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        model.press(5)
        model.state.press(AmountCalculator.Key.DoubleZero)
        model.state.update { copy(memo = "ランチ") }

        val saved = model.save()
        val entries = setup.database.entryList().entries

        assertTrue(saved)
        assertEquals(listOf(500), entries.map { it.amount })
        assertEquals(listOf("ランチ"), entries.map { it.memo })
        assertEquals(listOf(setup.today), entries.map { it.date })
        assertEquals(setup.now, entries.first().createdAt)
    }

    @Test
    fun savesOnceWhenSaveIsTappedTwice() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        model.press(5)

        val first = async { model.save() }
        val second = async { model.save() }
        val results = listOf(first.await(), second.await())

        assertEquals(1, results.count { it })
        assertEquals(1, setup.database.entryList().entries.size)
    }

    @Test
    fun refusesZeroAmount() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()

        val saved = model.save()

        assertFalse(saved)
        assertEquals("金額を入れてください", model.state.task.message)

        model.press(1)

        assertEquals("", model.state.task.message)
    }

    @Test
    fun refusesMissingCategory() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        model.press(5)
        model.state.update { copy(categoryId = null) }

        assertFalse(model.save())
        assertEquals("カテゴリを選んでください", model.state.task.message)
    }

    @Test
    fun editsExistingEntry() = modelTest(today = "2026-10-12") { setup ->
        val entry = setup.save(Entry.Kind.expense, amount = 980, on = setup.today, memo = "ランチ")
        val model = setup.loadedModel(editing = entry.id)

        val loadedAmount = model.output.amount
        val loadedMemo = model.state.form.memo
        model.state.press(AmountCalculator.Key.Delete)
        val saved = model.save()
        val stored = setup.database.entry(entry.id)

        assertTrue(model.output.isEditing)
        assertFalse(model.output.isBlank)
        assertEquals(980, loadedAmount)
        assertEquals("ランチ", loadedMemo)
        assertTrue(saved)
        assertEquals(98, stored?.amount)
        assertEquals(entry.createdAt, stored?.createdAt)
        assertEquals(1, setup.database.entryList().entries.size)
    }

    @Test
    fun reportsMissingEntryOnSave() = modelTest(today = "2026-10-12") { setup ->
        val entry = setup.save(Entry.Kind.expense, amount = 980, on = setup.today)
        val model = setup.loadedModel(editing = entry.id)
        setup.database.deleteEntry(id = entry.id, at = setup.now)

        val saved = model.save()

        assertFalse(saved)
        assertEquals("記録が見つかりませんでした", model.state.task.message)
    }

    @Test
    fun deletesExistingEntry() = modelTest(today = "2026-10-12") { setup ->
        val entry = setup.save(Entry.Kind.expense, amount = 980, on = setup.today)
        val model = setup.loadedModel(editing = entry.id)

        val deleted = model.delete()

        assertTrue(deleted)
        assertNull(setup.database.entry(entry.id))
    }

    @Test
    fun doesNotDeleteNewEntry() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()

        assertFalse(model.delete())
    }

    @Test
    fun startsNextEntryKeepingChoices() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        val options = setup.options()
        val daily = options.expenseCategories[1]
        val bank = options.wallets[1]
        model.state.select(daily)
        model.select(wallet = bank)
        model.press(5)
        model.state.update { copy(memo = "ランチ") }
        model.save()

        model.startNext()

        assertEquals(0, model.output.amount)
        assertEquals("", model.state.form.memo)
        assertEquals(daily.id, model.state.form.categoryId)
        assertEquals(bank.id, model.state.form.walletId)
        assertEquals(1, model.input.history?.entries?.size)
        assertEquals(listOf("ランチ"), model.input.recentMemos)
        assertFalse(model.output.isChanged)
    }

    @Test
    fun clearsTagWhenCategoryChanges() = modelTest(today = "2026-10-12") { setup ->
        val options = setup.options()
        val food = options.expenseCategories[0]
        val daily = options.expenseCategories[1]
        val tag = setup.addTags(categoryId = food.id, names = listOf("ランチ")).first()
        val model = setup.loadedModel()

        model.state.toggleTag(tag.id)
        val text = model.output.categoryText
        model.state.select(daily)

        assertEquals("${food.name}・ランチ", text)
        assertNull(model.state.form.tagId)
        assertEquals(daily.name, model.output.categoryText)
    }

    @Test
    fun describesDateFromToday() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()

        val today = model.output.dateValue
        model.state.select(date = date("2026-10-11"))
        val yesterday = model.output.dateValue
        model.state.select(date = date("2026-10-01"))
        val earlier = model.output.dateValue
        model.state.select(date = date("2025-12-31"))

        assertEquals("今日（月）", today)
        assertEquals("昨日（日）", yesterday)
        assertEquals("10/1（木）", earlier)
        assertEquals("2025/12/31（水）", model.output.dateValue)
    }

    @Test
    fun appliesTemplateToEntry() = modelTest(today = "2026-10-12") { setup ->
        val options = setup.options()
        val daily = options.expenseCategories[1]
        val bank = options.wallets[1]
        val template = setup.saveTemplate(
            EntryTemplateDraft(
                name = "日用品",
                type = Entry.Kind.expense,
                amount = 1200,
                categoryId = daily.id,
                walletId = bank.id,
                memo = "ドラッグストア",
            ),
        )
        val model = setup.loadedModel()

        model.apply(template)
        model.save()
        val entry = setup.database.entryList().entries.first()

        assertEquals(1200, entry.amount)
        assertEquals(daily.id, entry.categoryId)
        assertEquals(bank.id, entry.walletId)
        assertEquals("ドラッグストア", entry.memo)
        assertEquals(template.id, entry.templateId)
    }

    @Test
    fun keepsTypedAmountAndMemoWhenTemplateLacksThem() = modelTest(today = "2026-10-12") { setup ->
        val options = setup.options()
        val template = setup.saveTemplate(
            EntryTemplateDraft(
                name = "食費",
                type = Entry.Kind.expense,
                amount = null,
                categoryId = options.expenseCategories[0].id,
                walletId = options.wallets[0].id,
            ),
        )
        val model = setup.loadedModel()
        model.press(7)
        model.state.update { copy(memo = "おやつ") }

        model.apply(template)

        assertEquals(7, model.output.amount)
        assertEquals("おやつ", model.state.form.memo)
        assertEquals(EntryModel.Field.Amount, model.state.field)
    }

    @Test
    fun prefillsNewTemplateFromInput() = modelTest(today = "2026-10-12") { setup ->
        val model = setup.loadedModel()
        model.press(5)
        model.state.update { copy(memo = "ランチ") }

        val draft = model.output.newTemplateDraft()

        assertEquals("", draft.name)
        assertEquals(5, draft.amount)
        assertEquals("ランチ", draft.memo)
        assertEquals(model.state.form.categoryId, draft.categoryId)
        assertEquals(model.state.form.walletId, draft.walletId)
    }

    @Test
    fun listsRecentEntriesWithoutRepeats() = modelTest(today = "2026-10-12") { setup ->
        setup.save(Entry.Kind.expense, amount = 500, on = setup.today, memo = "ランチ")
        setup.save(Entry.Kind.expense, amount = 300, on = setup.today, memo = "おやつ")
        setup.save(Entry.Kind.expense, amount = 500, on = setup.today, memo = "ランチ")
        setup.save(Entry.Kind.income, amount = 9000, on = setup.today)
        val model = setup.loadedModel()

        val amounts = model.output.recentEntries.map { it.amount }
        model.applyRecent(model.output.recentEntries.last())

        assertEquals(listOf(500, 300), amounts)
        assertEquals(300, model.output.amount)
        assertEquals("おやつ", model.state.form.memo)
        assertTrue(model.output.hasRecent)
    }

    private suspend fun ModelTestSetup.saveTemplate(draft: EntryTemplateDraft) =
        database.saveTemplate(draft = draft, at = now)
}

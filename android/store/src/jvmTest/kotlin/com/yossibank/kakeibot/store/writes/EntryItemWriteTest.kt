package com.yossibank.kakeibot.store.writes

import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryBatchChange
import com.yossibank.kakeibot.core.concepts.entry.EntryItem
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.snapshot.snapshot
import com.yossibank.kakeibot.store.writes.methods.changeEntries
import com.yossibank.kakeibot.store.writes.methods.deleteEntries
import com.yossibank.kakeibot.store.writes.methods.deleteEntry
import com.yossibank.kakeibot.store.writes.methods.entryItems
import com.yossibank.kakeibot.store.writes.methods.forgetItemName
import com.yossibank.kakeibot.store.writes.methods.itemNames
import com.yossibank.kakeibot.store.writes.methods.recentItemNames
import com.yossibank.kakeibot.store.writes.methods.rememberItemName
import com.yossibank.kakeibot.store.writes.methods.restoreEntries
import com.yossibank.kakeibot.store.writes.methods.saveEntry
import kotlinx.coroutines.test.runTest
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class EntryItemWriteTest {
    @Test
    fun savesItemsInOrderWithTrimmedNames() = runTest {
        val setup = EntryWriteTest.Setup.make()
        val draft = setup.draft.copy(items = itemDrafts)

        val entry = setup.database.saveEntry(draft, at = setup.now)
        val items = setup.database.entryItems(of = entry.id)

        assertEquals(listOf("牛乳", "パン", "値引"), items.map { it.name })
        assertEquals(listOf(0, 1, 2), items.map { it.sortOrder })
        assertEquals(listOf(396, 220, -30), items.map { it.amount })
        assertEquals(listOf(2, 1, 1), items.map { it.quantity })

        setup.database.close()
    }

    @Test
    fun keepsIdsAndDropsExtraItemsWhenEdited() = runTest {
        val setup = EntryWriteTest.Setup.make()
        val later = setup.now.plusSeconds(60)
        val draft = setup.draft.copy(items = itemDrafts)
        val entry = setup.database.saveEntry(draft, at = setup.now)
        val before = setup.database.entryItems(of = entry.id)

        val edited = draft.copy(
            items = listOf(
                EntryItem.Draft(
                    name = "牛乳",
                    quantity = 2,
                    amount = 396,
                ),
            ),
        )

        setup.database.saveEntry(
            edited,
            editing = entry.id,
            at = later,
        )

        val after = setup.database.entryItems(of = entry.id)

        assertEquals(listOf(before[0].id), after.map { it.id })
        assertEquals(listOf(setup.now), after.map { it.updatedAt })

        setup.database.close()
    }

    @Test
    fun savesAndClearsTaxRate() = runTest {
        val setup = EntryWriteTest.Setup.make()
        val later = setup.now.plusSeconds(60)

        val draft = setup.draft.copy(
            items = listOf(
                EntryItem.Draft(
                    name = "牛乳",
                    amount = 396,
                    taxRate = AmountCalculator.TaxRate.reduced,
                ),
            ),
        )

        val entry = setup.database.saveEntry(draft, at = setup.now)
        val saved = setup.database.entryItems(of = entry.id)

        val edited = draft.copy(
            items = listOf(
                EntryItem.Draft(
                    name = "牛乳",
                    amount = 396,
                ),
            ),
        )

        setup.database.saveEntry(
            edited,
            editing = entry.id,
            at = later,
        )

        val cleared = setup.database.entryItems(of = entry.id)

        assertEquals(listOf(AmountCalculator.TaxRate.reduced), saved.map { it.taxRate })
        assertEquals(listOf(null), cleared.map { it.taxRate })
        assertEquals(listOf(later), cleared.map { it.updatedAt })

        setup.database.close()
    }

    @Test
    fun keepsItemsWhenDraftHasNone() = runTest {
        val setup = EntryWriteTest.Setup.make()
        val draft = setup.draft.copy(items = itemDrafts)
        val entry = setup.database.saveEntry(draft, at = setup.now)

        val edited = draft.copy(
            items = null,
            amount = 1200,
        )

        setup.database.saveEntry(
            edited,
            editing = entry.id,
            at = setup.now,
        )

        assertEquals(3, setup.database.entryItems(of = entry.id).size)

        setup.database.close()
    }

    @Test
    fun dropsItemsWhenEntryBecomesTransfer() = runTest {
        val setup = EntryWriteTest.Setup.make()
        val options = setup.database.entryOptions()
        val draft = setup.draft.copy(items = itemDrafts)
        val entry = setup.database.saveEntry(draft, at = setup.now)

        val edited = draft.copy(
            type = Entry.Kind.transfer,
            categoryId = null,
            items = null,
            toWalletId = options.wallets[1].id,
        )

        setup.database.saveEntry(
            edited,
            editing = entry.id,
            at = setup.now,
        )

        assertTrue(setup.database.entryItems(of = entry.id).isEmpty())

        setup.database.close()
    }

    @Test
    fun deletesItemsWithEntry() = runTest {
        val setup = EntryWriteTest.Setup.make()
        val draft = setup.draft.copy(items = itemDrafts)
        val entry = setup.database.saveEntry(draft, at = setup.now)

        setup.database.deleteEntry(entry.id)

        assertTrue(setup.database.snapshot().entryItems.isEmpty())

        setup.database.close()
    }

    @Test
    fun restoresItemsWithDeletedEntries() = runTest {
        val setup = EntryWriteTest.Setup.make()
        val draft = setup.draft.copy(items = itemDrafts)
        val entry = setup.database.saveEntry(draft, at = setup.now)
        val items = setup.database.entryItems(of = listOf(entry.id))

        val deleted = setup.database.deleteEntries(listOf(entry.id))

        setup.database.restoreEntries(
            deleted,
            items = items,
        )

        assertEquals(items, setup.database.entryItems(of = entry.id))

        setup.database.close()
    }

    @Test
    fun keepsItemsWhenRestoringWithoutItems() = runTest {
        val setup = EntryWriteTest.Setup.make()
        val options = setup.database.entryOptions()
        val draft = setup.draft.copy(items = itemDrafts)
        val entry = setup.database.saveEntry(draft, at = setup.now)
        val later = setup.now.plusSeconds(120)

        val previous = setup.database.changeEntries(
            listOf(entry.id),
            to = EntryBatchChange.Wallet(options.wallets[1].id),
            at = setup.now,
        )

        setup.database.restoreEntries(
            previous,
            at = later,
        )

        val items = setup.database.entryItems(of = entry.id)

        assertEquals(3, items.size)
        assertTrue(items.all { it.updatedAt == later })

        setup.database.close()
    }

    @Test
    fun touchesItemsWhenWalletChanges() = runTest {
        val setup = EntryWriteTest.Setup.make()
        val options = setup.database.entryOptions()
        val later = setup.now.plusSeconds(60)
        val draft = setup.draft.copy(items = itemDrafts)
        val entry = setup.database.saveEntry(draft, at = setup.now)

        setup.database.changeEntries(
            listOf(entry.id),
            to = EntryBatchChange.Wallet(options.wallets[1].id),
            at = later,
        )

        val items = setup.database.entryItems(of = entry.id)

        assertEquals(listOf(later, later, later), items.map { it.updatedAt })

        setup.database.close()
    }

    @Test
    fun remembersItemNamesPerStore() = runTest {
        val setup = EntryWriteTest.Setup.make()
        val database = setup.database

        database.rememberItemName(
            "牛乳",
            raw = "ｷﾞｭｳﾆｭｳ",
            at = "青葉",
            on = setup.now,
        )

        database.rememberItemName(
            "低脂肪乳",
            raw = "ｷﾞｭｳﾆｭｳ",
            at = "青葉",
            on = setup.now,
        )

        database.rememberItemName(
            "牛乳",
            raw = "ｷﾞｭｳﾆｭｳ",
            at = "若葉",
            on = setup.now,
        )

        database.rememberItemName(
            "  ",
            raw = "ﾊﾟﾝ",
            at = "青葉",
            on = setup.now,
        )

        val aoba = database.itemNames(at = "青葉")
        val count = database.snapshot().itemNames.size

        assertEquals(mapOf("ｷﾞｭｳﾆｭｳ" to "低脂肪乳"), aoba)
        assertEquals(2, count)

        database.close()
    }

    @Test
    fun forgetsItemNameOnlyAtTheStore() = runTest {
        val setup = EntryWriteTest.Setup.make()
        val database = setup.database

        database.rememberItemName(
            "牛乳",
            raw = "ｷﾞｭｳﾆｭｳ",
            at = "青葉",
            on = setup.now,
        )

        database.rememberItemName(
            "牛乳",
            raw = "ｷﾞｭｳﾆｭｳ",
            at = "若葉",
            on = setup.now,
        )

        database.forgetItemName(
            raw = "ｷﾞｭｳﾆｭｳ",
            at = "青葉",
        )

        database.forgetItemName(
            raw = "ﾊﾟﾝ",
            at = "青葉",
        )

        val aoba = database.itemNames(at = "青葉")
        val wakaba = database.itemNames(at = "若葉")

        assertTrue(aoba.isEmpty())
        assertEquals(mapOf("ｷﾞｭｳﾆｭｳ" to "牛乳"), wakaba)

        database.close()
    }

    @Test
    fun listsRecentItemNamesOnce() = runTest {
        val setup = EntryWriteTest.Setup.make()

        val batches = listOf(
            listOf("パン"),
            listOf("牛乳"),
            listOf("パン", "値引"),
            listOf("卵"),
        )

        for ((offset, names) in batches.withIndex()) {
            val draft = setup.draft.copy(
                items = names.map { name ->
                    EntryItem.Draft(
                        name = name,
                        amount = if (name == "値引") -30 else 100,
                    )
                },
            )

            setup.database.saveEntry(
                draft,
                at = setup.now.plusSeconds(offset * 60L),
            )
        }

        val recent = setup.database.recentItemNames(limit = 3)

        assertEquals(listOf("卵", "パン", "牛乳"), recent)

        setup.database.close()
    }
}

private val itemDrafts = listOf(
    EntryItem.Draft(
        name = " 牛乳 ",
        quantity = 2,
        amount = 396,
    ),
    EntryItem.Draft(
        name = "パン",
        amount = 220,
    ),
    EntryItem.Draft(
        name = "値引",
        amount = -30,
    ),
)

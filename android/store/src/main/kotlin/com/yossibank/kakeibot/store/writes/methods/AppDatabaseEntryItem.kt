package com.yossibank.kakeibot.store.writes.methods

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryItem
import com.yossibank.kakeibot.core.concepts.receipt.ItemName
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.read
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.protocols.storedValue
import com.yossibank.kakeibot.store.records.rows.EntryItemRecord
import com.yossibank.kakeibot.store.records.rows.ItemNameRecord
import com.yossibank.kakeibot.store.records.rows.entryItem
import com.yossibank.kakeibot.store.records.rows.itemName
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.values.databaseValue
import java.time.Instant

suspend fun AppDatabase.entryItems(of: Identifier<Entry>): List<EntryItem> = read {
    fetchEntryItems(of)
}

suspend fun AppDatabase.entryItems(of: List<Identifier<Entry>>): List<EntryItem> = read {
    fetchEntryItems(of)
}

suspend fun AppDatabase.recentItemNames(limit: Int): List<String> = read {
    entryItemDao().recentNames(limit)
}

suspend fun AppDatabase.itemNames(at: String): Map<String, String> = read {
    itemNameDao()
        .atStore(at)
        .map { it.decoded(ItemNameRecord::itemName) }
        .associate { it.raw to it.name }
}

suspend fun AppDatabase.rememberItemName(
    name: String,
    raw: String,
    at: String,
    on: Instant,
) {
    val trimmed = name.trim()

    if (trimmed.isEmpty()) {
        return
    }

    write {
        val existing = itemNameDao()
            .find(
                store = at,
                raw = raw,
            )
            ?.decoded(ItemNameRecord::itemName)

        if (existing != null && existing.name == trimmed) {
            return@write
        }

        val item = existing?.copy(
            name = trimmed,
            updatedAt = on,
        ) ?: ItemName(
            store = at,
            raw = raw,
            name = trimmed,
            createdAt = on,
            updatedAt = on,
        )

        itemNameDao().save(item.record())
    }
}

suspend fun AppDatabase.forgetItemName(
    raw: String,
    at: String,
) {
    write {
        itemNameDao().delete(
            store = at,
            raw = raw,
        )
    }
}

internal suspend fun AppDatabase.fetchEntryItems(of: List<Identifier<Entry>>): List<EntryItem> = entryItemDao()
    .ofEntries(of.map { it.databaseValue })
    .map { it.decoded(EntryItemRecord::entryItem) }

internal suspend fun AppDatabase.fetchEntryItems(of: Identifier<Entry>): List<EntryItem> = entryItemDao()
    .ofEntry(of.databaseValue)
    .map { it.decoded(EntryItemRecord::entryItem) }

internal suspend fun AppDatabase.saveItems(
    drafts: List<EntryItem.Draft>?,
    of: Entry,
    before: Entry?,
    at: Instant,
) {
    val existing = fetchEntryItems(of.id)

    if (of.type == Entry.Kind.transfer) {
        entryItemDao().deleteIds(existing.map { it.id.databaseValue })

        return
    }

    if (drafts != null) {
        replaceItems(
            existing = existing,
            with = drafts,
            of = of.id,
            at = at,
        )
    }

    if (before != null && (before.walletId != of.walletId || before.toWalletId != of.toWalletId)) {
        touchItems(
            of = listOf(of.id),
            at = at,
        )
    }
}

internal suspend fun AppDatabase.restoreItems(
    items: List<EntryItem>?,
    of: List<Identifier<Entry>>,
) {
    items ?: return

    entryItemDao().deleteOfEntries(
        entryIds = of.map { it.databaseValue },
        keptIds = items.map { it.id.databaseValue },
    )

    for (item in items) {
        if (entryDao().exists(item.entryId.databaseValue)) {
            entryItemDao().save(item.record())
        }
    }
}

internal suspend fun AppDatabase.touchItems(
    of: List<Identifier<Entry>>,
    at: Instant,
) {
    entryItemDao().touch(
        entryIds = of.map { it.databaseValue },
        updatedAt = at.storedValue,
    )
}

private suspend fun AppDatabase.replaceItems(
    existing: List<EntryItem>,
    with: List<EntryItem.Draft>,
    of: Identifier<Entry>,
    at: Instant,
) {
    for ((index, draft) in with.withIndex()) {
        val old = existing.getOrNull(index)

        val base = old ?: EntryItem(
            entryId = of,
            name = draft.trimmedName,
            quantity = draft.quantity,
            amount = draft.amount,
            taxRate = draft.taxRate,
            sortOrder = index,
            createdAt = at,
            updatedAt = at,
        )

        val item = base.copy(
            name = draft.trimmedName,
            quantity = draft.quantity,
            amount = draft.amount,
            taxRate = draft.taxRate,
            sortOrder = index,
        )

        if (item == old) {
            continue
        }

        entryItemDao().save(item.copy(updatedAt = at).record())
    }

    val removed = existing.drop(with.size).map { it.id.databaseValue }

    entryItemDao().deleteIds(removed)
}

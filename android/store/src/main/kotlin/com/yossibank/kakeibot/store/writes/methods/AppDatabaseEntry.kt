package com.yossibank.kakeibot.store.writes.methods

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.category.EntryTag
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryBatchChange
import com.yossibank.kakeibot.core.concepts.entry.EntryDraft
import com.yossibank.kakeibot.core.concepts.entry.NoSpendDay
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.feeCategoryId
import com.yossibank.kakeibot.store.database.read
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.EntryCategoryRecord
import com.yossibank.kakeibot.store.records.rows.EntryRecord
import com.yossibank.kakeibot.store.records.rows.NoSpendDayRecord
import com.yossibank.kakeibot.store.records.rows.entry
import com.yossibank.kakeibot.store.records.rows.entryCategory
import com.yossibank.kakeibot.store.records.rows.noSpendDay
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.records.values.fromDatabaseValue
import com.yossibank.kakeibot.store.writes.types.SavedEntry
import java.time.Instant

enum class WriteError {
    entryNotFound,
    tagMismatch,
}

class WriteException(
    val error: WriteError,
) : Exception(error.name)

suspend fun AppDatabase.saveEntry(
    draft: EntryDraft,
    editing: Identifier<Entry>? = null,
    at: Instant,
): Entry = saveEntryResult(
    draft = draft,
    editing = editing,
    at = at,
).entry

suspend fun AppDatabase.saveEntryResult(
    draft: EntryDraft,
    editing: Identifier<Entry>? = null,
    at: Instant,
): SavedEntry = write {
    saveEntryRecalculating(
        draft = draft,
        editing = editing,
        at = at,
    )
}

suspend fun AppDatabase.saveEntries(
    drafts: List<EntryDraft>,
    at: Instant,
) {
    write {
        val change = CardBillChange()

        for (draft in drafts) {
            saveEntry(
                draft = draft,
                editing = null,
                change = change,
                at = at,
            )
        }

        recalculateCardBills(
            change = change,
            at = at,
        )
    }
}

suspend fun AppDatabase.fee(of: Identifier<Entry>): Entry? = read {
    fetchFee(of)
}

suspend fun AppDatabase.deleteEntry(
    id: Identifier<Entry>,
    restoringNoSpend: List<NoSpendDay> = emptyList(),
    at: Instant = Instant.now(),
): List<Entry> = deleteEntries(
    ids = listOf(id),
    restoringNoSpend = restoringNoSpend,
    at = at,
)

suspend fun AppDatabase.deleteEntries(
    ids: List<Identifier<Entry>>,
    restoringNoSpend: List<NoSpendDay> = emptyList(),
    at: Instant = Instant.now(),
): List<Entry> = write {
    val keys = ids.map { it.databaseValue }
    val entries = entryDao().withIds(keys).map { it.decoded(EntryRecord::entry) }
    val fees = entryDao().feesOutside(keys).map { it.decoded(EntryRecord::entry) }
    val deleted = entries + fees
    val change = CardBillChange(before = deleted)

    detachRewardGoals(
        from = deleted.map { it.id },
        at = at,
    )

    entryDao().deleteIds(keys)
    restoreNoSpendDays(restoringNoSpend)

    recalculateCardBills(
        change = change,
        at = at,
    )

    deleted
}

suspend fun AppDatabase.changeEntries(
    ids: List<Identifier<Entry>>,
    to: EntryBatchChange,
    at: Instant,
): List<Entry> = write {
    val entries = entryDao()
        .withIds(ids.map { it.databaseValue })
        .map { it.decoded(EntryRecord::entry) }
        .filter { it.type != Entry.Kind.transfer }

    val changed = entries.filter {
        canChange(
            entry = it,
            to = to,
        )
    }

    val touched = CardBillChange()

    for (original in changed) {
        touched.before += original

        val moved = when (to) {
            is EntryBatchChange.Category -> original.copy(
                categoryId = to.id,
                tagId = null,
            )

            is EntryBatchChange.Wallet -> original.copy(
                walletId = to.id,
                billMonth = null,
            )
        }

        val entry = fitCategory(moved.copy(updatedAt = at))

        entryDao().update(entry.record())
        touched.after += entry
    }

    if (to is EntryBatchChange.Wallet) {
        touchItems(
            of = changed.map { it.id },
            at = at,
        )
    }

    recalculateCardBills(
        change = touched,
        at = at,
    )

    changed
}

internal suspend fun AppDatabase.saveEntryRecalculating(
    draft: EntryDraft,
    editing: Identifier<Entry>?,
    at: Instant,
): SavedEntry {
    val change = CardBillChange()

    val saved = saveEntry(
        draft = draft,
        editing = editing,
        change = change,
        at = at,
    )

    recalculateCardBills(
        change = change,
        at = at,
    )

    return saved
}

internal suspend fun AppDatabase.saveEntry(
    draft: EntryDraft,
    editing: Identifier<Entry>?,
    change: CardBillChange,
    at: Instant,
): SavedEntry {
    val before = editing?.let { findEntry(it) }
    val beforeFee = before?.let { fetchFee(it.id) }

    val drafted = entry(
        from = draft,
        editing = editing,
        at = at,
    )

    val entry = fitCategory(drafted)

    val belongs = tag(
        id = entry.tagId,
        belongsTo = entry.categoryId,
    )

    if (!belongs) {
        throw WriteException(WriteError.tagMismatch)
    }

    entryDao().save(entry.record())

    saveItems(
        drafts = draft.items,
        of = entry,
        before = before,
        at = at,
    )

    val cleared = mutableListOf<NoSpendDay>()

    if (entry.type == Entry.Kind.expense) {
        cleared += clearNoSpendDay(entry.date)
    }

    cleared += saveFee(
        amount = draft.fee,
        transfer = entry,
        at = at,
    )

    val afterFee = fetchFee(entry.id)

    change.before += listOfNotNull(before, beforeFee)
    change.after += listOfNotNull(entry, afterFee)

    return SavedEntry(
        entry = entry,
        clearedNoSpendDays = cleared,
    )
}

internal suspend fun AppDatabase.clearNoSpendDay(on: LocalDate): List<NoSpendDay> {
    val day = noSpendDayDao().find(on.databaseValue)?.decoded(NoSpendDayRecord::noSpendDay) ?: return emptyList()

    noSpendDayDao().delete(on.databaseValue)

    return listOf(day)
}

internal suspend fun AppDatabase.fetchFee(of: Identifier<Entry>): Entry? =
    entryDao().fee(of.databaseValue)?.decoded(EntryRecord::entry)

internal suspend fun AppDatabase.saveFee(
    amount: Int,
    transfer: Entry,
    at: Instant,
): List<NoSpendDay> {
    val existing = fetchFee(transfer.id)

    if (transfer.type != Entry.Kind.transfer || amount <= 0) {
        existing?.let { entryDao().delete(it.id.databaseValue) }

        return emptyList()
    }

    val base = existing ?: newFee(
        amount = amount,
        transfer = transfer,
        at = at,
    )

    val fee = fitCategory(
        base.copy(
            amount = amount,
            date = transfer.date,
            walletId = transfer.walletId,
            billMonth = null,
            updatedAt = at,
        ),
    )

    entryDao().save(fee.record())

    return clearNoSpendDay(fee.date)
}

internal suspend fun AppDatabase.findEntry(id: Identifier<Entry>): Entry? =
    entryDao().find(id.databaseValue)?.decoded(EntryRecord::entry)

internal suspend fun AppDatabase.fitCategory(entry: Entry): Entry {
    val categoryId = entry.categoryId ?: return entry
    val category = categoryDao().find(categoryId.databaseValue)?.decoded(EntryCategoryRecord::entryCategory) ?: return entry

    if (category.walletId == null) {
        return entry
    }

    val fitted = categoryDao().firstIdWithoutWallet(
        kind = category.kind.rawValue,
        name = category.name,
    ) ?: return entry

    val tagId = entry.tagId?.let { tagId ->
        tagDao().firstId(
            tagId = tagId.databaseValue,
            categoryId = fitted,
        )
    }

    return entry.copy(
        categoryId = Identifier.fromDatabaseValue<EntryCategory>(fitted),
        tagId = tagId?.let { Identifier.fromDatabaseValue<EntryTag>(it) },
    )
}

private suspend fun AppDatabase.canChange(
    entry: Entry,
    to: EntryBatchChange,
): Boolean = when (to) {
    is EntryBatchChange.Category -> {
        val category = categoryDao().find(to.id.databaseValue)?.decoded(EntryCategoryRecord::entryCategory)

        category?.kind?.rawValue == entry.type.rawValue
    }

    is EntryBatchChange.Wallet -> entry.transferId == null && walletDao().exists(to.id.databaseValue)
}

private suspend fun AppDatabase.entry(
    from: EntryDraft,
    editing: Identifier<Entry>?,
    at: Instant,
): Entry {
    editing ?: return from.newEntry(at)

    val existing = findEntry(editing) ?: throw WriteException(WriteError.entryNotFound)

    return from.applied(
        to = existing,
        at = at,
    )
}

private suspend fun AppDatabase.newFee(
    amount: Int,
    transfer: Entry,
    at: Instant,
): Entry {
    val categoryId = feeCategoryId(at)

    return Entry(
        type = Entry.Kind.expense,
        amount = amount,
        date = transfer.date,
        categoryId = categoryId,
        walletId = transfer.walletId,
        transferId = transfer.id,
        createdAt = at,
        updatedAt = at,
    )
}

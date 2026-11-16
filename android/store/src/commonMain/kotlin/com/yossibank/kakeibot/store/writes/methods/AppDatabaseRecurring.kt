package com.yossibank.kakeibot.store.writes.methods

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.RecurringDraft
import com.yossibank.kakeibot.core.concepts.recurring.amount
import com.yossibank.kakeibot.core.concepts.recurring.billingPeriod
import com.yossibank.kakeibot.core.concepts.recurring.isRecorded
import com.yossibank.kakeibot.core.concepts.recurring.occurrence
import com.yossibank.kakeibot.core.concepts.recurring.occurrences
import com.yossibank.kakeibot.core.concepts.recurring.pendingOccurrences
import com.yossibank.kakeibot.core.concepts.recurring.scheduledAmount
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.protocols.nextSortOrder
import com.yossibank.kakeibot.store.records.protocols.reorder
import com.yossibank.kakeibot.store.records.rows.EntryRecord
import com.yossibank.kakeibot.store.records.rows.RecurringRecord
import com.yossibank.kakeibot.store.records.rows.entry
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.rows.recurring
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.writes.types.Deletion
import java.time.Instant

enum class RecurringWriteError {
    recurringNotFound,
}

class RecurringWriteException(
    val error: RecurringWriteError,
) : Exception(error.name)

suspend fun AppDatabase.saveRecurring(
    draft: RecurringDraft,
    editing: Identifier<Recurring>? = null,
    today: LocalDate,
    at: Instant,
): Recurring = write {
    val change = CardBillChange()

    val recurring = if (editing != null) {
        val current = findRecurring(editing) ?: throw RecurringWriteException(RecurringWriteError.recurringNotFound)

        val updated = draft.applied(
            to = current,
            at = at,
        )

        recurringDao().update(updated.record())

        generateEarlierEntries(
            of = updated,
            before = current.startDate,
            through = today,
            change = change,
            at = at,
        )

        updated
    } else {
        val sortOrder = nextSortOrder(recurringDao().maxSortOrder())
        val inserted = draft.newRecurring(at).copy(sortOrder = sortOrder)

        recurringDao().insert(inserted.record())

        inserted
    }

    generateEntries(
        of = recurring,
        through = today,
        change = change,
        at = at,
    )

    recalculateCardBills(
        change = change,
        at = at,
    )

    findRecurring(recurring.id) ?: recurring
}

suspend fun AppDatabase.setRecurringHidden(
    id: Identifier<Recurring>,
    isHidden: Boolean,
    today: LocalDate,
    at: Instant,
) {
    write {
        val current = findRecurring(id) ?: throw RecurringWriteException(RecurringWriteError.recurringNotFound)

        val generatedUntil = if (isHidden) {
            current.generatedUntil
        } else {
            val yesterday = today.adding(days = -1)
            val generated = current.generatedUntil ?: yesterday

            maxOf(generated, yesterday)
        }

        val recurring = current.copy(
            archivedAt = if (isHidden) at else null,
            updatedAt = at,
            generatedUntil = generatedUntil,
        )

        recurringDao().update(recurring.record())

        val change = CardBillChange()

        generateEntries(
            of = recurring,
            through = today,
            change = change,
            at = at,
        )

        recalculateCardBills(
            change = change,
            at = at,
        )
    }
}

suspend fun AppDatabase.deleteRecurring(
    id: Identifier<Recurring>,
    at: Instant,
): Deletion = write {
    val recurrings = listOfNotNull(findRecurring(id))

    deleteRecurrings(
        recurrings = recurrings,
        at = at,
    )
}

suspend fun AppDatabase.reorderRecurrings(
    ids: List<Identifier<Recurring>>,
    at: Instant,
) {
    write {
        reorder(
            table = "recurring",
            ids = ids.map { it.databaseValue },
            notFound = RecurringWriteException(RecurringWriteError.recurringNotFound),
            now = at,
        )
    }
}

suspend fun AppDatabase.recordRecurring(
    id: Identifier<Recurring>,
    on: LocalDate,
    at: Instant,
): Entry? = write {
    val recurring = findRecurring(id) ?: return@write null
    val change = CardBillChange()

    val entry = generateEntry(
        of = recurring,
        on = recurring.occurrence(on = on),
        change = change,
        at = at,
    )

    recalculateCardBills(
        change = change,
        at = at,
    )

    entry
}

suspend fun AppDatabase.generateRecurringEntries(
    through: LocalDate,
    at: Instant,
) {
    write {
        val change = CardBillChange()
        val recurrings = recurringDao().all().map { it.decoded(RecurringRecord::recurring) }

        for (recurring in recurrings) {
            generateEntries(
                of = recurring,
                through = through,
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

internal suspend fun AppDatabase.insertEntry(
    of: Recurring,
    on: Recurring.Occurrence,
    at: Instant,
): Entry? {
    val date = on.date

    val exists = entryDao()
        .ofRecurring(
            recurringId = of.id.databaseValue,
            earliest = on.scheduled.adding(days = -40).databaseValue,
            latest = on.scheduled.adding(days = 40).databaseValue,
        )
        .map { it.decoded(EntryRecord::entry) }
        .any {
            of.isRecorded(
                by = it,
                scheduled = on.scheduled,
            )
        }

    val amount = billAmount(
        of = of,
        on = on,
    )

    if (exists || amount <= 0) {
        return null
    }

    val billMonth = billMonth(
        paidBy = of.walletId,
        type = of.type,
        on = date,
        shift = of.billShift,
    )

    val entry = fitCategory(
        Entry(
            type = of.type,
            amount = amount.toInt(),
            date = date,
            categoryId = of.categoryId,
            walletId = of.walletId,
            toWalletId = of.toWalletId,
            memo = of.memo,
            recurringId = of.id,
            recurringDate = on.scheduled,
            billMonth = billMonth,
            createdAt = at,
            updatedAt = at,
        ),
    )

    entryDao().insert(entry.record())

    if (entry.type == Entry.Kind.expense) {
        noSpendDayDao().delete(date.databaseValue)
    }

    saveFee(
        amount = of.fee ?: 0,
        transfer = entry,
        at = at,
    )

    return entry
}

internal suspend fun AppDatabase.billAmount(
    of: Recurring,
    on: Recurring.Occurrence,
): Long {
    if (of.billingPeriod(paidOn = on.date) == null || of.toWalletId == null) {
        return of.scheduledAmount(paidOn = on.date).toLong()
    }

    val entries = billEntries(
        of = of,
        on = on,
    )

    return of.amount(
        paidOn = on.date,
        entries = entries,
    )
}

internal suspend fun AppDatabase.billEntries(
    of: Recurring,
    on: Recurring.Occurrence,
): List<Entry> {
    val period = of.billingPeriod(paidOn = on.date) ?: return emptyList()
    val card = of.toWalletId ?: return emptyList()

    return entryDao()
        .billed(
            card = card.databaseValue,
            start = period.start.databaseValue,
            end = period.endInclusive.databaseValue,
            month = on.scheduled.yearMonth.databaseValue,
        )
        .map { it.decoded(EntryRecord::entry) }
}

private suspend fun AppDatabase.findRecurring(id: Identifier<Recurring>): Recurring? =
    recurringDao().find(id.databaseValue)?.decoded(RecurringRecord::recurring)

private suspend fun AppDatabase.generateEntries(
    of: Recurring,
    through: LocalDate,
    change: CardBillChange,
    at: Instant,
) {
    val occurrences = if (of.archivedAt == null) of.pendingOccurrences(through = through) else emptyList()

    for (occurrence in occurrences) {
        generateEntry(
            of = of,
            on = occurrence,
            change = change,
            at = at,
        )
    }

    if (of.startDate > through) {
        return
    }

    recurringDao().setGeneratedUntil(
        id = of.id.databaseValue,
        date = through.databaseValue,
    )
}

private suspend fun AppDatabase.generateEarlierEntries(
    of: Recurring,
    before: LocalDate,
    through: LocalDate,
    change: CardBillChange,
    at: Instant,
) {
    if (of.archivedAt != null || of.startDate >= before) {
        return
    }

    val dayBefore = before.adding(days = -1)
    val last = minOf(dayBefore, through)

    val occurrences = of.occurrences(
        from = of.startDate,
        through = last,
    )

    for (occurrence in occurrences) {
        generateEntry(
            of = of,
            on = occurrence,
            change = change,
            at = at,
        )
    }
}

private suspend fun AppDatabase.generateEntry(
    of: Recurring,
    on: Recurring.Occurrence,
    change: CardBillChange,
    at: Instant,
): Entry? {
    val entry = insertEntry(
        of = of,
        on = on,
        at = at,
    )

    if (entry != null) {
        change.after += entry

        fetchFee(entry.id)?.let { change.after += it }
    }

    return entry
}

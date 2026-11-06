package com.yossibank.kakeibot.store.writes.methods

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.amount
import com.yossibank.kakeibot.core.concepts.recurring.billMonth
import com.yossibank.kakeibot.core.concepts.recurring.billingPeriod
import com.yossibank.kakeibot.core.concepts.recurring.isRecorded
import com.yossibank.kakeibot.core.concepts.recurring.occurrences
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.EntryRecord
import com.yossibank.kakeibot.store.records.rows.RecurringRecord
import com.yossibank.kakeibot.store.records.rows.entry
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.rows.recurring
import com.yossibank.kakeibot.store.records.values.databaseValue
import java.time.Instant

internal class CardBillChange(
    before: List<Entry> = emptyList(),
    after: List<Entry> = emptyList(),
) {
    val before: MutableList<Entry> = before.toMutableList()
    val after: MutableList<Entry> = after.toMutableList()
}

internal suspend fun AppDatabase.recalculateCardBills(
    change: CardBillChange,
    at: Instant,
    visited: Set<Identifier<Recurring>> = emptySet(),
) {
    val changed = change.before + change.after
    val cards = changed.map { it.walletId }.toSet()

    if (cards.isEmpty()) {
        return
    }

    val recurrings = recurringDao()
        .billing(cards.map { it.databaseValue })
        .map { it.decoded(RecurringRecord::recurring) }
        .filter { it.id !in visited }

    val cascade = CardBillChange()

    for (recurring in recurrings) {
        val card = recurring.toWalletId ?: continue
        val until = recurring.generatedUntil ?: continue
        val entries = changed.filter { it.walletId == card }

        val occurrences = recurring.occurrences(
            affectedBy = entries,
            through = until,
        )

        for (occurrence in occurrences) {
            val billChange = recalculateBill(
                of = recurring,
                on = occurrence,
                after = change,
                at = at,
            )

            cascade.before += billChange.before
            cascade.after += billChange.after
        }
    }

    val passed = visited + recurrings.map { it.id }

    recalculateCardBills(
        change = cascade,
        at = at,
        visited = passed,
    )
}

internal suspend fun AppDatabase.billMonth(
    paidBy: Identifier<Wallet>,
    type: Entry.Kind,
    on: LocalDate,
    shift: Int,
): YearMonth? {
    if (type == Entry.Kind.transfer || shift <= 0) {
        return null
    }

    val bill = recurringDao().cardBill(paidBy.databaseValue)?.decoded(RecurringRecord::recurring)

    return bill?.billMonth(
        used = on,
        shift = shift,
    )
}

internal suspend fun AppDatabase.existingRows(of: List<Entry>): List<Entry> {
    val ids = of.map { it.id.databaseValue }
    val rows = entryDao().withIds(ids).map { it.decoded(EntryRecord::entry) }.toMutableList()

    for (entry in of) {
        sameRecurrence(entry)?.let { rows += it }
    }

    val rowIds = rows.map { it.id.databaseValue }
    val fees = entryDao().fees(rowIds).map { it.decoded(EntryRecord::entry) }

    return (rows + fees).distinctBy { it.id }
}

internal suspend fun AppDatabase.sameRecurrence(entry: Entry): List<Entry>? {
    val recurringId = entry.recurringId ?: return null
    val month = entry.recurringDate?.yearMonth ?: return null

    val first = LocalDate.of(
        yearMonth = month,
        day = 1,
    ) ?: return null

    val next = LocalDate.of(
        yearMonth = month.adding(months = 1),
        day = 1,
    ) ?: return null

    return entryDao()
        .ofRecurrence(
            recurringId = recurringId.databaseValue,
            first = first.databaseValue,
            next = next.databaseValue,
        )
        .map { it.decoded(EntryRecord::entry) }
}

private const val MAX_PERIOD_DAYS = 31
private const val MAX_PAYMENT_LAG_DAYS = 31
private const val MAX_HOLIDAY_SHIFT_DAYS = 10
private const val BILL_SEARCH_DAYS = MAX_PERIOD_DAYS + MAX_PAYMENT_LAG_DAYS + MAX_HOLIDAY_SHIFT_DAYS

private suspend fun AppDatabase.recalculateBill(
    of: Recurring,
    on: Recurring.Occurrence,
    after: CardBillChange,
    at: Instant,
): CardBillChange {
    val used = billEntries(
        of = of,
        on = on,
    )

    val amount = of.amount(
        paidOn = on.date,
        entries = used,
    )

    val bill = entryDao()
        .ofRecurring(
            recurringId = of.id.databaseValue,
            earliest = on.scheduled.adding(days = -40).databaseValue,
            latest = on.scheduled.adding(days = 40).databaseValue,
        )
        .map { it.decoded(EntryRecord::entry) }
        .firstOrNull {
            of.isRecorded(
                by = it,
                scheduled = on.scheduled,
            )
        }

    if (bill == null) {
        val changedIds = after.after.map { it.id }.toSet()
        val previous = used.filter { it.id !in changedIds } + after.before

        val previousAmount = of.amount(
            paidOn = on.date,
            entries = previous,
        )

        if (previousAmount != 0L || amount <= 0 || of.archivedAt != null) {
            return CardBillChange()
        }

        val inserted = insertEntry(
            of = of,
            on = on,
            at = at,
        ) ?: return CardBillChange()

        val fees = entryDao().fees(listOf(inserted.id.databaseValue)).map { it.decoded(EntryRecord::entry) }

        return CardBillChange(after = listOf(inserted) + fees)
    }

    if (bill.updatedAt != bill.createdAt || bill.amount.toLong() == amount) {
        return CardBillChange()
    }

    if (amount <= 0) {
        val removed = entryDao().fees(listOf(bill.id.databaseValue)).map { it.decoded(EntryRecord::entry) }

        entryDao().deleteFees(listOf(bill.id.databaseValue))
        entryDao().delete(bill.id.databaseValue)

        return CardBillChange(before = listOf(bill) + removed)
    }

    val recalculated = bill.copy(amount = amount.toInt())

    entryDao().update(recalculated.record())

    return CardBillChange(
        before = listOf(bill),
        after = listOf(recalculated),
    )
}

private fun Recurring.occurrences(
    affectedBy: List<Entry>,
    through: LocalDate,
): List<Recurring.Occurrence> {
    val found = mutableListOf<Recurring.Occurrence>()

    for (entry in affectedBy) {
        val candidates = candidates(
            entry = entry,
            through = through,
        )

        for (occurrence in candidates) {
            if (occurrence !in found) {
                found += occurrence
            }
        }
    }

    return found
}

private fun Recurring.candidates(
    entry: Entry,
    through: LocalDate,
): List<Recurring.Occurrence> {
    val shift = MAX_HOLIDAY_SHIFT_DAYS
    val paidStart = entry.date.adding(days = -shift)
    val searchEnd = entry.date.adding(days = BILL_SEARCH_DAYS)
    val paidEnd = minOf(searchEnd, through)

    val paid = occurrences(
        from = paidStart,
        through = paidEnd,
    ).filter { billingPeriod(paidOn = it.date)?.contains(entry.date) == true }

    val month = entry.billMonth ?: return paid

    val first = LocalDate.of(
        yearMonth = month,
        day = 1,
    ) ?: return paid

    val next = LocalDate.of(
        yearMonth = month.adding(months = 1),
        day = 1,
    ) ?: return paid

    val carriedStart = first.adding(days = -shift)
    val shiftedNext = next.adding(days = shift)
    val carriedEnd = minOf(shiftedNext, through)

    val carried = occurrences(
        from = carriedStart,
        through = carriedEnd,
    ).filter { it.scheduled.yearMonth == month }

    return paid + carried
}

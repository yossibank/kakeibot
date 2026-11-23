package com.yossibank.kakeibot.store.writes.methods

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.RecurringDraft
import com.yossibank.kakeibot.core.concepts.recurring.occurrence
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.protocols.nextSortOrder
import com.yossibank.kakeibot.store.records.protocols.reorder
import com.yossibank.kakeibot.store.records.rows.RecurringRecord
import com.yossibank.kakeibot.store.records.rows.entry
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.rows.recurring
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.writes.types.CardBillChange
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
        val current =
            findRecurring(editing)
                ?: throw RecurringWriteException(RecurringWriteError.recurringNotFound)

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
        val current =
            findRecurring(id)
                ?: throw RecurringWriteException(RecurringWriteError.recurringNotFound)

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

suspend fun AppDatabase.deleteRecurrings(
    ids: List<Identifier<Recurring>>,
    at: Instant,
): Deletion = write {
    val recurrings = ids.mapNotNull { findRecurring(it) }

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

private suspend fun AppDatabase.findRecurring(id: Identifier<Recurring>): Recurring? =
    recurringDao().find(id.databaseValue)?.decoded(RecurringRecord::recurring)

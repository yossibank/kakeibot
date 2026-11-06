package com.yossibank.kakeibot.store.queries.methods

import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.observation
import com.yossibank.kakeibot.store.database.read
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.RecurringRecord
import com.yossibank.kakeibot.store.records.rows.recurring
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged

fun AppDatabase.recurringUpdates(includingHidden: Boolean = false): Flow<List<Recurring>> = observation("recurring") {
    fetchRecurrings(includingHidden)
}.distinctUntilChanged()

suspend fun AppDatabase.recurrings(includingHidden: Boolean = false): List<Recurring> = read {
    fetchRecurrings(includingHidden)
}

internal suspend fun AppDatabase.fetchRecurrings(includingHidden: Boolean = false): List<Recurring> {
    val records = if (includingHidden) recurringDao().inOrder() else recurringDao().unarchivedInOrder()

    return records.map { it.decoded(RecurringRecord::recurring) }
}

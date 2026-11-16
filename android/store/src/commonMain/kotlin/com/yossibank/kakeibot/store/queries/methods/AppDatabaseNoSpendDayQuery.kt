package com.yossibank.kakeibot.store.queries.methods

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.observation
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.NoSpendDayRecord
import com.yossibank.kakeibot.store.records.rows.noSpendDay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged

fun AppDatabase.noSpendDayUpdates(): Flow<Set<LocalDate>> = observation("no_spend_day") {
    fetchNoSpendDays()
}.distinctUntilChanged()

internal suspend fun AppDatabase.fetchNoSpendDays(): Set<LocalDate> = noSpendDayDao()
    .all()
    .map { it.decoded(NoSpendDayRecord::noSpendDay).date }
    .toSet()

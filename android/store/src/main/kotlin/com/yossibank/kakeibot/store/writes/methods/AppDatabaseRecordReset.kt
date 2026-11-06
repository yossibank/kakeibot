package com.yossibank.kakeibot.store.writes.methods

import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.read
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.EntryRecord
import com.yossibank.kakeibot.store.records.rows.entry
import java.time.Instant

suspend fun AppDatabase.deletableRecordCount(): Int = read {
    val counts = listOf(
        entryDao().count(),
        valuationDao().count(),
        adjustmentDao().count(),
        rewardLogDao().count(),
        calendarStampDao().count(),
        noSpendDayDao().count(),
    )

    counts.sum()
}

suspend fun AppDatabase.deleteAllRecords(at: Instant = Instant.now()) {
    write {
        val entries = entryDao().all().map { it.decoded(EntryRecord::entry) }
        val change = CardBillChange(before = entries)

        detachRewardGoals(
            from = entries.map { it.id },
            at = at,
        )

        entryDao().deleteAll()
        valuationDao().deleteAll()
        adjustmentDao().deleteAll()
        rewardLogDao().deleteAll()
        calendarStampDao().deleteAll()
        noSpendDayDao().deleteAll()

        recalculateCardBills(
            change = change,
            at = at,
        )
    }
}

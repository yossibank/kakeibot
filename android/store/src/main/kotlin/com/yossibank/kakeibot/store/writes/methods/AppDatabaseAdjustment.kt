package com.yossibank.kakeibot.store.writes.methods

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.wallet.Adjustment
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.AdjustmentRecord
import com.yossibank.kakeibot.store.records.rows.adjustment
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.writes.types.Deletion
import java.time.Instant

suspend fun AppDatabase.saveAdjustment(
    amount: Long,
    of: Identifier<Wallet>,
    on: LocalDate,
    at: Instant,
): Adjustment? {
    if (amount == 0L) {
        return null
    }

    return write {
        val adjustment = Adjustment(
            walletId = of,
            date = on,
            amount = amount,
            createdAt = at,
            updatedAt = at,
        )

        adjustmentDao().insert(adjustment.record())

        adjustment
    }
}

suspend fun AppDatabase.deleteAdjustment(id: Identifier<Adjustment>): Deletion? = write {
    val adjustment = adjustmentDao().find(id.databaseValue)?.decoded(AdjustmentRecord::adjustment) ?: return@write null

    adjustmentDao().delete(id.databaseValue)

    Deletion(adjustments = listOf(adjustment))
}

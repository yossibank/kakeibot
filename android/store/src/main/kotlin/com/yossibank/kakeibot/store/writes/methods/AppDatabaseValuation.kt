package com.yossibank.kakeibot.store.writes.methods

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.wallet.Valuation
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.ValuationRecord
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.rows.valuation
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.writes.types.Deletion
import java.time.Instant

suspend fun AppDatabase.saveValuation(
    amount: Int,
    of: Identifier<Wallet>,
    on: LocalDate,
    at: Instant,
): Valuation = write {
    valuationDao().deleteOn(
        walletId = of.databaseValue,
        date = on.databaseValue,
    )

    val valuation = Valuation(
        walletId = of,
        date = on,
        amount = amount,
        createdAt = at,
        updatedAt = at,
    )

    valuationDao().insert(valuation.record())

    valuation
}

suspend fun AppDatabase.deleteValuation(id: Identifier<Valuation>): Deletion? = write {
    val valuation = valuationDao().find(id.databaseValue)?.decoded(ValuationRecord::valuation) ?: return@write null

    valuationDao().delete(id.databaseValue)

    Deletion(valuations = listOf(valuation))
}

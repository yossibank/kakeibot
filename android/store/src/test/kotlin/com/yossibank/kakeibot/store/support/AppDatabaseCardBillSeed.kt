package com.yossibank.kakeibot.store.support

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.records.rows.record
import java.time.Instant
import kotlin.test.assertNotNull

suspend fun AppDatabase.insertCardBill(at: Instant): Recurring {
    val options = entryOptions()
    val bank = options.wallets[1]
    val start = assertNotNull(LocalDate.parse("2026-01-01"))

    val card = Wallet(
        name = "カード",
        kind = Wallet.Kind.card,
        iconId = bank.iconId,
        initialBalance = 0,
        sortOrder = 9,
        createdAt = at,
        updatedAt = at,
    )

    val bill = Recurring(
        type = Entry.Kind.transfer,
        amount = 0,
        categoryId = null,
        walletId = bank.id,
        toWalletId = card.id,
        frequency = Recurring.Frequency.monthly,
        day = 27,
        closingDay = 15,
        startDate = start,
        createdAt = at,
        updatedAt = at,
    )

    write {
        walletDao().insert(card.record())
        recurringDao().insert(bill.record())
    }

    return bill
}

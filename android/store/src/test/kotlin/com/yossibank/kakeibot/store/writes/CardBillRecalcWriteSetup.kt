package com.yossibank.kakeibot.store.writes

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryDraft
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.insertDefaultsIfEmpty
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.snapshot.snapshot
import com.yossibank.kakeibot.store.writes.methods.generateRecurringEntries
import com.yossibank.kakeibot.store.writes.methods.saveEntry
import java.time.Instant
import kotlin.test.assertNotNull

suspend fun CardBillRecalcWriteTest.Setup.Companion.make(usage: List<Int>): CardBillRecalcWriteTest.Setup {
    val database = AppDatabase.inMemory()
    val now = Instant.ofEpochSecond(1_791_000_000)
    val startDate = assertNotNull(LocalDate.parse("2026-11-01"))
    val through = assertNotNull(LocalDate.parse("2026-11-10"))

    database.insertDefaultsIfEmpty(now)

    val options = database.entryOptions()
    val bank = options.wallets[0].id
    val card = options.wallets[1].id
    val category = options.expenseCategories[0].id

    val bill = Recurring(
        type = Entry.Kind.transfer,
        amount = 0,
        categoryId = null,
        walletId = bank,
        toWalletId = card,
        frequency = Recurring.Frequency.monthly,
        day = 10,
        closingDay = 15,
        startDate = startDate,
        createdAt = now,
        updatedAt = now,
    )

    database.recurringDao().insert(bill.record())

    val setup = CardBillRecalcWriteTest.Setup(
        database = database,
        now = now,
        bank = bank,
        card = card,
        category = category,
        recurringId = bill.id,
    )

    for (amount in usage) {
        setup.spend(amount, on = "2026-10-01")
    }

    database.generateRecurringEntries(
        through = through,
        at = now,
    )

    return setup
}

suspend fun CardBillRecalcWriteTest.Setup.spend(
    amount: Int,
    on: String,
    wallet: Identifier<Wallet>? = null,
): Entry {
    val day = assertNotNull(LocalDate.parse(on))

    val draft = EntryDraft(
        type = Entry.Kind.expense,
        amount = amount,
        date = day,
        categoryId = category,
        walletId = wallet ?: card,
    )

    return database.saveEntry(draft, at = now)
}

suspend fun CardBillRecalcWriteTest.Setup.bill(of: Identifier<Recurring> = recurringId): Entry? =
    database.snapshot().entries.firstOrNull { it.recurringId == of }

suspend fun CardBillRecalcWriteTest.Setup.bills(): List<Entry> =
    database.snapshot().entries.filter { it.recurringId == recurringId }

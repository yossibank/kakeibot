package com.yossibank.kakeibot.core.concepts.recurring

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import java.time.Instant
import kotlin.test.assertNotNull

internal object CardBillFixture {
    data class Bill(
        val from: Identifier<Wallet>,
        val to: Identifier<Wallet>,
        val amount: Int,
        val day: Int,
    )

    fun wallet(
        kind: Wallet.Kind,
        balance: Int,
        at: Instant,
    ): Wallet = Wallet(
        name = kind.rawValue,
        kind = kind,
        iconId = Identifier(),
        initialBalance = balance,
        sortOrder = 0,
        createdAt = at,
        updatedAt = at,
    )

    fun recurring(
        from: Identifier<Wallet>,
        to: Identifier<Wallet>,
        amount: Int,
        day: Int,
        closingDay: Int? = null,
    ): Recurring {
        val now = Instant.ofEpochSecond(1_791_000_000)

        return Recurring(
            type = Entry.Kind.transfer,
            amount = amount,
            categoryId = null,
            walletId = from,
            toWalletId = to,
            frequency = Recurring.Frequency.monthly,
            day = day,
            closingDay = closingDay,
            startDate = date("2026-01-01"),
            createdAt = now,
            updatedAt = now,
        )
    }

    fun entry(
        type: Entry.Kind,
        amount: Int,
        on: String,
        wallet: Identifier<Wallet>,
    ): Entry {
        val now = Instant.ofEpochSecond(1_791_000_000)

        return Entry(
            type = type,
            amount = amount,
            date = date(on),
            categoryId = null,
            walletId = wallet,
            createdAt = now,
            updatedAt = now,
        )
    }

    fun date(text: String): LocalDate = assertNotNull(LocalDate.parse(text))
}

package com.yossibank.kakeibot.core.concepts.recurring

import com.yossibank.kakeibot.core.concepts.date.HolidayShift
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import java.time.Instant
import kotlin.test.assertNotNull

internal object RecurringCardBillFixture {
    fun date(text: String): LocalDate = assertNotNull(LocalDate.parse(text))

    fun bill(
        closingDay: Int,
        day: Int = 10,
        holidayShift: HolidayShift = HolidayShift.none,
    ): Recurring {
        val now = Instant.ofEpochSecond(1_791_000_000)

        return Recurring(
            type = Entry.Kind.transfer,
            amount = 45000,
            categoryId = null,
            walletId = Identifier(),
            toWalletId = Identifier(),
            frequency = Recurring.Frequency.monthly,
            day = day,
            holidayShift = holidayShift,
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
}

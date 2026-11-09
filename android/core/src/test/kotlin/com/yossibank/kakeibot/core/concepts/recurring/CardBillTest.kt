package com.yossibank.kakeibot.core.concepts.recurring

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.wallet.Adjustment
import com.yossibank.kakeibot.core.concepts.wallet.Valuation
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

class CardBillTest {
    @Test
    fun subtractsBillsFromSourceInDateOrder() {
        val now = Instant.ofEpochSecond(1_791_000_000)
        val today = date("2026-10-20")
        val start = date("2026-01-01")

        val bank = wallet(
            kind = Wallet.Kind.bank,
            balance = 60000,
            at = now,
        )

        val first = wallet(
            kind = Wallet.Kind.card,
            balance = 0,
            at = now,
        )

        val second = wallet(
            kind = Wallet.Kind.card,
            balance = 0,
            at = now,
        )

        val bills = listOf(
            Bill(
                from = bank.id,
                to = second.id,
                amount = 40000,
                day = 27,
            ),
            Bill(
                from = bank.id,
                to = first.id,
                amount = 30000,
                day = 26,
            ),
        ).map { bill ->
            Recurring(
                type = Entry.Kind.transfer,
                amount = bill.amount,
                categoryId = null,
                walletId = bill.from,
                toWalletId = bill.to,
                frequency = Recurring.Frequency.monthly,
                day = bill.day,
                startDate = start,
                createdAt = now,
                updatedAt = now,
            )
        }

        val upcoming = CardBill.upcoming(
            recurrings = bills,
            wallets = listOf(bank, first, second),
            entries = emptyList(),
            valuations = emptyList(),
            adjustments = emptyList(),
            after = today,
        )

        assertEquals(listOf(26, 27), upcoming.map { it.date.day })
        assertEquals(listOf(60000L, 30000L), upcoming.map { it.balanceBefore })
        assertEquals(listOf(0L, 10000L), upcoming.map { it.shortage })
    }

    @Test
    fun startsFromValuationOfSource() {
        val now = Instant.ofEpochSecond(1_791_000_000)
        val today = date("2026-10-20")
        val start = date("2026-01-01")

        val source = wallet(
            kind = Wallet.Kind.investment,
            balance = 10000,
            at = now,
        )

        val card = wallet(
            kind = Wallet.Kind.card,
            balance = 0,
            at = now,
        )

        val bill = Recurring(
            type = Entry.Kind.transfer,
            amount = 30000,
            categoryId = null,
            walletId = source.id,
            toWalletId = card.id,
            frequency = Recurring.Frequency.monthly,
            day = 27,
            startDate = start,
            createdAt = now,
            updatedAt = now,
        )

        val valuation = Valuation(
            walletId = source.id,
            date = date("2026-10-01"),
            amount = 50000,
            createdAt = now,
            updatedAt = now,
        )

        val upcoming = CardBill.upcoming(
            recurrings = listOf(bill),
            wallets = listOf(source, card),
            entries = emptyList(),
            valuations = listOf(valuation),
            adjustments = emptyList(),
            after = today,
        )

        assertEquals(listOf(50000L), upcoming.map { it.balanceBefore })
        assertEquals(listOf(0L), upcoming.map { it.shortage })
    }

    @Test
    fun startsFromAdjustedBalanceOfSource() {
        val now = Instant.ofEpochSecond(1_791_000_000)
        val today = date("2026-10-20")
        val start = date("2026-01-01")

        val source = wallet(
            kind = Wallet.Kind.bank,
            balance = 10000,
            at = now,
        )

        val card = wallet(
            kind = Wallet.Kind.card,
            balance = 0,
            at = now,
        )

        val bill = Recurring(
            type = Entry.Kind.transfer,
            amount = 30000,
            categoryId = null,
            walletId = source.id,
            toWalletId = card.id,
            frequency = Recurring.Frequency.monthly,
            day = 27,
            startDate = start,
            createdAt = now,
            updatedAt = now,
        )

        val adjustment = Adjustment(
            walletId = source.id,
            date = today,
            amount = 5000,
            createdAt = now,
            updatedAt = now,
        )

        val upcoming = CardBill.upcoming(
            recurrings = listOf(bill),
            wallets = listOf(source, card),
            entries = emptyList(),
            valuations = emptyList(),
            adjustments = listOf(adjustment),
            after = today,
        )

        assertEquals(listOf(15000L), upcoming.map { it.balanceBefore })
        assertEquals(listOf(15000L), upcoming.map { it.shortage })
    }

    @Test
    fun subtractsWithoutWrappingAround() {
        val limit = 999_999_999
        val now = Instant.ofEpochSecond(1_791_000_000)
        val today = date("2026-10-20")

        val source = wallet(
            kind = Wallet.Kind.bank,
            balance = limit,
            at = now,
        )

        val card = wallet(
            kind = Wallet.Kind.card,
            balance = 0,
            at = now,
        )

        val bill = Recurring(
            type = Entry.Kind.transfer,
            amount = limit,
            categoryId = null,
            walletId = source.id,
            toWalletId = card.id,
            frequency = Recurring.Frequency.monthly,
            day = 27,
            startDate = date("2026-01-01"),
            createdAt = now,
            updatedAt = now,
        )

        val upcoming = CardBill.upcoming(
            recurrings = listOf(
                bill,
                bill.copy(id = Identifier(), day = 28),
                bill.copy(id = Identifier(), day = 29),
            ),
            wallets = listOf(source, card),
            entries = emptyList(),
            valuations = emptyList(),
            adjustments = emptyList(),
            after = today,
        )

        assertEquals(listOf(limit.toLong(), 0L, -limit.toLong()), upcoming.map { it.balanceBefore })
        assertEquals(-2L * limit, upcoming.last().balanceAfter)
    }

    @Test
    fun countsSourceRecordsBeforeBillDate() {
        val now = Instant.ofEpochSecond(1_791_000_000)
        val today = date("2026-10-20")

        val bank = wallet(
            kind = Wallet.Kind.bank,
            balance = 100_000,
            at = now,
        )

        val card = wallet(
            kind = Wallet.Kind.card,
            balance = 0,
            at = now,
        )

        val entries = listOf(
            entry(Entry.Kind.expense, 10000, on = "2026-10-26", wallet = bank.id),
            entry(Entry.Kind.income, 280_000, on = "2026-10-27", wallet = bank.id),
            entry(Entry.Kind.income, 50000, on = "2026-11-25", wallet = bank.id),
        )

        val bill = recurring(
            from = bank.id,
            to = card.id,
            amount = 30000,
            day = 27,
        )

        val upcoming = CardBill.upcoming(
            recurrings = listOf(bill),
            wallets = listOf(bank, card),
            entries = entries,
            valuations = emptyList(),
            adjustments = emptyList(),
            after = today,
        )

        assertEquals(listOf(90000L), upcoming.map { it.balanceBefore })
    }

    @Test
    fun listsBillsOfEachCardUpToCount() {
        val now = Instant.ofEpochSecond(1_791_000_000)
        val today = date("2026-10-20")

        val bank = wallet(
            kind = Wallet.Kind.bank,
            balance = 100_000,
            at = now,
        )

        val first = wallet(
            kind = Wallet.Kind.card,
            balance = 0,
            at = now,
        )

        val second = wallet(
            kind = Wallet.Kind.card,
            balance = 0,
            at = now,
        )

        val recurrings = listOf(
            recurring(from = bank.id, to = first.id, amount = 30000, day = 26),
            recurring(from = bank.id, to = second.id, amount = 20000, day = 10),
        )

        val entries = listOf(
            entry(Entry.Kind.income, 280_000, on = "2026-10-27", wallet = bank.id),
            entry(Entry.Kind.expense, 5000, on = "2026-11-26", wallet = bank.id),
        )

        val upcoming = CardBill.upcoming(
            recurrings = recurrings,
            wallets = listOf(bank, first, second),
            entries = entries,
            valuations = emptyList(),
            adjustments = emptyList(),
            after = today,
            count = 2,
        )

        assertEquals(
            listOf("2026-10-26", "2026-11-10", "2026-11-26", "2026-12-10"),
            upcoming.map { it.date.toString() },
        )

        assertEquals(
            listOf(100_000L, 350_000L, 330_000L, 295_000L),
            upcoming.map { it.balanceBefore },
        )
    }

    @Test
    fun marksBillBeforeClosingAsOpen() {
        val now = Instant.ofEpochSecond(1_791_000_000)
        val today = date("2026-10-16")

        val bank = wallet(
            kind = Wallet.Kind.bank,
            balance = 100_000,
            at = now,
        )

        val card = wallet(
            kind = Wallet.Kind.card,
            balance = 0,
            at = now,
        )

        val fixed = wallet(
            kind = Wallet.Kind.card,
            balance = 0,
            at = now,
        )

        val recurrings = listOf(
            recurring(from = bank.id, to = card.id, amount = 0, day = 26, closingDay = 15),
            recurring(from = bank.id, to = fixed.id, amount = 30000, day = 27),
        )

        val upcoming = CardBill.upcoming(
            recurrings = recurrings,
            wallets = listOf(bank, card, fixed),
            entries = emptyList(),
            valuations = emptyList(),
            adjustments = emptyList(),
            after = today,
            count = 2,
        )

        assertEquals(listOf(false, false, true, false), upcoming.map { it.isOpen })
        assertEquals(
            listOf("2026-10", "2026-10", "2026-11", "2026-11"),
            upcoming.map { it.month.toString() },
        )
    }

    private data class Bill(
        val from: Identifier<Wallet>,
        val to: Identifier<Wallet>,
        val amount: Int,
        val day: Int,
    )

    private fun wallet(
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

    private fun recurring(
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

    private fun entry(
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

    private fun date(text: String): LocalDate = assertNotNull(LocalDate.parse(text))
}

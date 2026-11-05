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
        assertEquals(listOf(60000, 30000), upcoming.map { it.balanceBefore })
        assertEquals(listOf(0, 10000), upcoming.map { it.shortage })
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

        assertEquals(listOf(50000), upcoming.map { it.balanceBefore })
        assertEquals(listOf(0), upcoming.map { it.shortage })
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

        assertEquals(listOf(15000), upcoming.map { it.balanceBefore })
        assertEquals(listOf(15000), upcoming.map { it.shortage })
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

    private fun date(text: String): LocalDate = assertNotNull(LocalDate.parse(text))
}

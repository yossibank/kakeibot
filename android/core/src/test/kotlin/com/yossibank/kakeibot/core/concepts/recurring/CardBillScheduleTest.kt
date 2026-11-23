package com.yossibank.kakeibot.core.concepts.recurring

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.recurring.CardBillFixture.date
import com.yossibank.kakeibot.core.concepts.recurring.CardBillFixture.entry
import com.yossibank.kakeibot.core.concepts.recurring.CardBillFixture.recurring
import com.yossibank.kakeibot.core.concepts.recurring.CardBillFixture.wallet
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals

class CardBillScheduleTest {
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

    @Test
    fun measuresProgressThroughBillingPeriod() {
        val now = Instant.ofEpochSecond(1_791_000_000)
        val bank = wallet(kind = Wallet.Kind.bank, balance = 0, at = now)
        val card = wallet(kind = Wallet.Kind.card, balance = 0, at = now)

        val bill = CardBill(
            recurring = recurring(
                from = bank.id,
                to = card.id,
                amount = 0,
                day = 26,
                closingDay = 15,
            ),
            date = date("2026-11-26"),
            amount = 0,
            balanceBefore = 0,
        )

        val cases = listOf(
            "2026-10-15" to 0.0,
            "2026-10-16" to 1.0 / 31,
            "2026-10-31" to 16.0 / 31,
            "2026-11-15" to 1.0,
            "2026-11-20" to 1.0,
        )

        for ((day, expected) in cases) {
            assertEquals(expected, bill.progress(on = date(day)), 0.0001)
        }
    }

    @Test
    fun treatsBillWithoutClosingDayAsDone() {
        val now = Instant.ofEpochSecond(1_791_000_000)
        val bank = wallet(kind = Wallet.Kind.bank, balance = 0, at = now)
        val card = wallet(kind = Wallet.Kind.card, balance = 0, at = now)

        val bill = CardBill(
            recurring = recurring(from = bank.id, to = card.id, amount = 30000, day = 27),
            date = date("2026-11-27"),
            amount = 30000,
            balanceBefore = 0,
        )

        assertEquals(1.0, bill.progress(on = date("2026-11-01")))
    }
}

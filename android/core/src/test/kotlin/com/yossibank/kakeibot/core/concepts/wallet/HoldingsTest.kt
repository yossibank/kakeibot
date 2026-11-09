package com.yossibank.kakeibot.core.concepts.wallet

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.shared.Identifier
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

class HoldingsTest {
    @Test
    fun splitsAvailableMoneyFromNetWorth() {
        val wallets = listOf(
            wallet(Wallet.Kind.bank, 489_700),
            wallet(Wallet.Kind.card, -52000),
            wallet(Wallet.Kind.investment, 300_000),
            wallet(Wallet.Kind.loan, -1_200_000),
        )

        val holdings = Holdings(
            wallets = wallets,
            entriesByWallet = emptyMap(),
        )

        assertEquals(437_700, holdings.available)
        assertEquals(52000, holdings.unpaid)
        assertEquals(0, holdings.refund)
        assertEquals(-462_300, holdings.netWorth)
    }

    @Test
    fun showsRefundWhenCardIsPositive() {
        val wallets = listOf(
            wallet(Wallet.Kind.cash, 10000),
            wallet(Wallet.Kind.card, 3000),
        )

        val holdings = Holdings(
            wallets = wallets,
            entriesByWallet = emptyMap(),
        )

        assertEquals(0, holdings.unpaid)
        assertEquals(3000, holdings.refund)
        assertEquals(13000, holdings.available)
    }

    @Test
    fun sumsWithoutWrappingAround() {
        val limit = 999_999_999

        val wallets = List(3) { wallet(Wallet.Kind.bank, limit) }

        val holdings = Holdings(
            wallets = wallets,
            entriesByWallet = emptyMap(),
        )

        assertEquals(3L * limit, holdings.onHand)
        assertEquals(3L * limit, holdings.available)
        assertEquals(3L * limit, holdings.netWorth)
    }

    @Test
    fun countsOnlyChangesToAvailableMoney() {
        val bank = wallet(Wallet.Kind.bank, 0)
        val card = wallet(Wallet.Kind.card, 0)
        val investment = wallet(Wallet.Kind.investment, 0)
        val wallets = listOf(bank, card, investment)
        val expense = entry(Entry.Kind.expense, from = bank.id)
        val charge = entry(Entry.Kind.transfer, from = bank.id, to = card.id)
        val saving = entry(Entry.Kind.transfer, from = bank.id, to = investment.id)
        val dividend = entry(Entry.Kind.income, from = investment.id)

        assertEquals(-3000, expense.availableChange(wallets))
        assertEquals(0, charge.availableChange(wallets))
        assertEquals(-3000, saving.availableChange(wallets))
        assertEquals(0, dividend.availableChange(wallets))
    }

    private fun wallet(
        kind: Wallet.Kind,
        balance: Int,
    ): Wallet {
        val now = Instant.ofEpochSecond(1_791_000_000)

        return Wallet(
            name = kind.rawValue,
            kind = kind,
            iconId = Identifier(),
            initialBalance = balance,
            sortOrder = 0,
            createdAt = now,
            updatedAt = now,
        )
    }

    private fun entry(
        type: Entry.Kind,
        from: Identifier<Wallet>,
        to: Identifier<Wallet>? = null,
    ): Entry {
        val now = Instant.ofEpochSecond(1_791_000_000)

        return Entry(
            type = type,
            amount = 3000,
            date = assertNotNull(LocalDate.parse("2026-10-01")),
            categoryId = if (type == Entry.Kind.transfer) null else Identifier(),
            walletId = from,
            toWalletId = to,
            createdAt = now,
            updatedAt = now,
        )
    }
}

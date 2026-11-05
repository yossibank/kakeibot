package com.yossibank.kakeibot.core.concepts.wallet

import com.yossibank.kakeibot.core.shared.Identifier
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals

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
            entries = emptyList(),
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
            entries = emptyList(),
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
            entries = emptyList(),
        )

        assertEquals(3L * limit, holdings.onHand)
        assertEquals(3L * limit, holdings.available)
        assertEquals(3L * limit, holdings.netWorth)
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
}

package com.yossibank.kakeibot.core.concepts.wallet

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.core.support.CoreFixture
import kotlinx.serialization.Serializable
import org.junit.Test
import org.junit.experimental.runners.Enclosed
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

@RunWith(Enclosed::class)
class WalletBalanceTest {
    @RunWith(Parameterized::class)
    class CountsEntriesThroughDate(
        private val fixture: BalanceCase,
    ) {
        @Serializable
        data class BalanceCase(
            val summary: String,
            val kind: Wallet.Kind? = null,
            val initialBalance: Int,
            val entries: List<EntryCase>,
            val valuations: List<ValuationCase>? = null,
            val adjustments: List<AdjustmentCase>? = null,
            val through: LocalDate? = null,
            val balance: Long,
        ) {
            override fun toString(): String = summary
        }

        @Serializable
        data class ValuationCase(
            val date: LocalDate,
            val amount: Int,
            val createdAt: String? = null,
        )

        @Serializable
        data class AdjustmentCase(
            val date: LocalDate,
            val amount: Long,
            val wallet: Side,
        )

        @Serializable
        data class EntryCase(
            val type: Entry.Kind,
            val amount: Int,
            val date: LocalDate,
            val wallet: Side,
            val toWallet: Side? = null,
            val createdAt: String? = null,
        )

        @Serializable
        enum class Side {
            self,
            other,
        }

        @Test
        fun countsEntriesThroughDate() {
            val other = Identifier<Wallet>()

            val wallet = wallet(
                kind = fixture.kind ?: Wallet.Kind.cash,
                initialBalance = fixture.initialBalance,
            )

            val entries = fixture.entries.map { entry ->
                Entry(
                    type = entry.type,
                    amount = entry.amount,
                    date = entry.date,
                    categoryId = if (entry.type == Entry.Kind.transfer) null else Identifier(),
                    walletId = if (entry.wallet == Side.self) wallet.id else other,
                    toWalletId = entry.toWallet?.let { if (it == Side.self) wallet.id else other },
                    createdAt = entry.createdAt?.let(Instant::parse) ?: recordedAt,
                    updatedAt = Instant.now(),
                )
            }

            val valuations = (fixture.valuations ?: emptyList()).map { valuation ->
                Valuation(
                    walletId = wallet.id,
                    date = valuation.date,
                    amount = valuation.amount,
                    createdAt = valuation.createdAt?.let(Instant::parse) ?: valuedAt,
                    updatedAt = Instant.now(),
                )
            }

            val adjustments = (fixture.adjustments ?: emptyList()).map { adjustment ->
                Adjustment(
                    walletId = if (adjustment.wallet == Side.self) wallet.id else other,
                    date = adjustment.date,
                    amount = adjustment.amount,
                    createdAt = recordedAt,
                    updatedAt = Instant.now(),
                )
            }

            val balance = wallet.balance(
                with = entries,
                valuations = valuations,
                adjustments = adjustments,
                through = fixture.through,
            )

            assertEquals(fixture.balance, balance)
        }

        companion object {
            private val recordedAt = Instant.ofEpochSecond(0)
            private val valuedAt = Instant.ofEpochSecond(1)

            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<BalanceCase> = CoreFixture.cases("wallet/wallet-balance.json", BalanceCase.serializer())
        }
    }

    class Totals {
        @Test
        fun sumsWallets() {
            val cash = wallet(initialBalance = 1000)
            val card = wallet(initialBalance = -500)
            val date = assertNotNull(LocalDate.parse("2026-10-01"))

            val entry = Entry(
                type = Entry.Kind.expense,
                amount = 300,
                date = date,
                categoryId = Identifier(),
                walletId = cash.id,
                createdAt = Instant.now(),
                updatedAt = Instant.now(),
            )

            val holdings = Holdings(
                wallets = listOf(cash, card),
                entriesByWallet = Wallet.entriesByWallet(listOf(entry)),
            )

            assertEquals(200, holdings.onHand)
        }

        @Test
        fun addsAdjustmentBeyondIntRange() {
            val cash = wallet(initialBalance = 0)
            val date = assertNotNull(LocalDate.parse("2026-10-01"))

            val adjustment = Adjustment(
                walletId = cash.id,
                date = date,
                amount = 3_000_000_000L,
                createdAt = Instant.now(),
                updatedAt = Instant.now(),
            )

            val balance = cash.balance(
                with = emptyList(),
                adjustments = listOf(adjustment),
            )

            assertEquals(3_000_000_000L, balance)
        }

        @Test
        fun sumsWithoutWrappingAround() {
            val date = assertNotNull(LocalDate.parse("2026-10-01"))
            val limit = 999_999_999

            val wallets = List(3) { wallet(initialBalance = limit) }

            val entries = wallets.map { wallet ->
                Entry(
                    type = Entry.Kind.income,
                    amount = limit,
                    date = date,
                    categoryId = Identifier(),
                    walletId = wallet.id,
                    createdAt = Instant.now(),
                    updatedAt = Instant.now(),
                )
            }

            val holdings = Holdings(
                wallets = wallets,
                entriesByWallet = Wallet.entriesByWallet(entries),
            )

            assertEquals(6L * limit, holdings.onHand)
        }

        @Test
        fun keepsRepaidWithinBorrowed() {
            assertEquals(200_000L, Wallet.repaid(borrowed = 300_000, balance = -100_000))
            assertEquals(0L, Wallet.repaid(borrowed = 300_000, balance = -500_000))
            assertEquals(300_000L, Wallet.repaid(borrowed = 300_000, balance = 50000))
        }

        @Test
        fun groupsEntriesByBothWalletsOfTransfer() {
            val cash = Identifier<Wallet>()
            val bank = Identifier<Wallet>()
            val date = assertNotNull(LocalDate.parse("2026-10-01"))

            val expense = Entry(
                type = Entry.Kind.expense,
                amount = 300,
                date = date,
                categoryId = Identifier(),
                walletId = cash,
                createdAt = Instant.now(),
                updatedAt = Instant.now(),
            )

            val transfer = Entry(
                type = Entry.Kind.transfer,
                amount = 1000,
                date = date,
                categoryId = null,
                walletId = bank,
                toWalletId = cash,
                createdAt = Instant.now(),
                updatedAt = Instant.now(),
            )

            val grouped = Wallet.entriesByWallet(
                listOf(
                    expense,
                    transfer,
                ),
            )

            assertEquals(
                listOf(
                    expense.id,
                    transfer.id,
                ),
                grouped[cash]?.map { it.id },
            )

            assertEquals(
                listOf(transfer.id),
                grouped[bank]?.map { it.id },
            )
        }
    }
}

private fun wallet(
    kind: Wallet.Kind = Wallet.Kind.cash,
    initialBalance: Int,
): Wallet = Wallet(
    name = "財布",
    kind = kind,
    iconId = Identifier(),
    initialBalance = initialBalance,
    sortOrder = 0,
    createdAt = Instant.now(),
    updatedAt = Instant.now(),
)

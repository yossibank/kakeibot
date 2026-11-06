package com.yossibank.kakeibot.core.concepts.wallet

import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.icon.IconDraft
import com.yossibank.kakeibot.core.shared.DraftProblem
import com.yossibank.kakeibot.core.support.CoreFixture
import com.yossibank.kakeibot.core.support.FixtureMark
import kotlinx.serialization.Serializable
import org.junit.Test
import org.junit.experimental.runners.Enclosed
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertNull

@RunWith(Enclosed::class)
class WalletDraftTest {
    @RunWith(Parameterized::class)
    class FindsProblems(
        private val fixture: DraftCase,
    ) {
        @Serializable
        data class DraftCase(
            val summary: String,
            val name: String,
            val kind: Wallet.Kind,
            val recordedKind: Wallet.Kind? = null,
            val hasValuations: Boolean? = null,
            val mark: FixtureMark,
            val color: String,
            val initialBalance: Int,
            val problems: List<DraftProblem>,
        ) {
            override fun toString(): String = summary
        }

        @Test
        fun findsProblems() {
            val draft = WalletDraft(
                kind = fixture.kind,
                name = fixture.name,
                mark = fixture.mark.mark(),
                color = fixture.color,
                initialBalance = fixture.initialBalance,
                recordedKind = fixture.recordedKind,
                hasValuations = fixture.hasValuations ?: false,
            )

            assertEquals(fixture.problems, draft.problems)
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<DraftCase> = CoreFixture.cases("wallet/wallet-draft.json", DraftCase.serializer())
        }
    }

    @RunWith(Parameterized::class)
    class KeepsLoanAmountOnlyForLoans(
        private val kind: Wallet.Kind,
        private val amount: Int,
        private val expected: Int?,
    ) {
        @Test
        fun keepsLoanAmountOnlyForLoans() {
            val now = Instant.ofEpochSecond(1_791_000_000)

            val draft = WalletDraft(
                kind = kind,
                name = "奨学金",
                mark = IconDraft.Mark.Text("奨"),
                color = "#BF4040",
                initialBalance = -240_000,
                loanAmount = amount,
            )

            val icon = draft.newIcon(now)

            val wallet = draft.newWallet(
                iconId = icon.id,
                sortOrder = 0,
                at = now,
            )

            assertEquals(expected, wallet.loanAmount)
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0} {1}")
            fun cases(): List<Array<Any?>> = listOf(
                arrayOf(Wallet.Kind.loan, 300_000, 300_000),
                arrayOf(Wallet.Kind.loan, 0, null),
                arrayOf(Wallet.Kind.bank, 300_000, null),
            )
        }
    }

    class Making {
        @Test
        fun makesWalletWithTrimmedName() {
            val now = Instant.ofEpochSecond(1_791_000_000)

            val draft = WalletDraft(
                kind = Wallet.Kind.card,
                name = " 楽天カード ",
                mark = IconDraft.Mark.Text("楽"),
                color = "#BF4040",
                initialBalance = -38000,
            )

            val icon = draft.newIcon(now)

            val wallet = draft.newWallet(
                iconId = icon.id,
                sortOrder = 4,
                at = now,
            )

            assertEquals("楽", icon.text)
            assertEquals("楽天カード", wallet.name)
            assertEquals(Wallet.Kind.card, wallet.kind)
            assertEquals(-38000, wallet.initialBalance)
            assertEquals(icon.id, wallet.iconId)
            assertEquals(4, wallet.sortOrder)
        }

        @Test
        fun keepsIdentityWhenApplied() {
            val created = Instant.ofEpochSecond(1_790_000_000)
            val now = Instant.ofEpochSecond(1_791_000_000)

            val icon = Icon(
                emoji = null,
                text = null,
                glyph = Icon.Glyph.bank,
                color = "#8DB0EA",
                createdAt = created,
                updatedAt = created,
            )

            val wallet = Wallet(
                name = "銀行",
                kind = Wallet.Kind.bank,
                iconId = icon.id,
                initialBalance = 0,
                sortOrder = 1,
                createdAt = created,
                updatedAt = created,
            )

            val draft = WalletDraft(
                wallet = wallet,
                icon = icon,
            ).copy(
                name = "ゆうちょ",
                initialBalance = 120_000,
                mark = IconDraft.Mark.Emoji("📮"),
            )

            val updatedIcon = draft.applied(
                to = icon,
                at = now,
            )

            val updatedWallet = draft.applied(
                to = wallet,
                at = now,
            )

            assertEquals(icon.id, updatedIcon.id)
            assertEquals("📮", updatedIcon.emoji)
            assertNull(updatedIcon.glyph)
            assertEquals(wallet.id, updatedWallet.id)
            assertEquals("ゆうちょ", updatedWallet.name)
            assertEquals(120_000, updatedWallet.initialBalance)
            assertEquals(1, updatedWallet.sortOrder)
            assertEquals(created, updatedWallet.createdAt)
            assertEquals(now, updatedWallet.updatedAt)
        }
    }
}

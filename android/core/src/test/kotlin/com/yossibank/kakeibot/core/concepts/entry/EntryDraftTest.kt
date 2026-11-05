package com.yossibank.kakeibot.core.concepts.entry

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.core.support.CoreFixture
import kotlinx.serialization.Serializable
import org.junit.Test
import org.junit.experimental.runners.Enclosed
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNotNull
import kotlin.test.assertNull

@RunWith(Enclosed::class)
class EntryDraftTest {
    @RunWith(Parameterized::class)
    class FindsProblems(
        private val fixture: DraftCase,
    ) {
        @Serializable
        data class DraftCase(
            val summary: String,
            val type: Entry.Kind,
            val amount: Int,
            val category: Boolean,
            val tag: Boolean,
            val toWallet: Destination,
            val fee: Int? = null,
            val items: List<ItemCase>? = null,
            val problems: List<EntryDraft.Problem>,
        ) {
            override fun toString(): String = summary
        }

        @Serializable
        data class ItemCase(
            val name: String,
            val quantity: Int,
            val amount: Int,
        )

        @Serializable
        enum class Destination {
            none,
            same,
            other,
        }

        @Test
        fun findsProblems() {
            val walletId = Identifier<Wallet>()

            val toWalletId = when (fixture.toWallet) {
                Destination.none -> null
                Destination.same -> walletId
                Destination.other -> Identifier()
            }

            val items = fixture.items?.map { item ->
                EntryItem.Draft(
                    name = item.name,
                    quantity = item.quantity,
                    amount = item.amount,
                )
            }

            val draft = EntryDraft(
                type = fixture.type,
                amount = fixture.amount,
                date = date("2026-10-01"),
                categoryId = if (fixture.category) Identifier() else null,
                tagId = if (fixture.tag) Identifier() else null,
                walletId = walletId,
                toWalletId = toWalletId,
                fee = fixture.fee ?: 0,
                items = items,
            )

            assertEquals(fixture.problems, draft.problems)
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<DraftCase> = CoreFixture.cases("entry/entry-draft.json", DraftCase.serializer())
        }
    }

    class Making {
        @Test
        fun makesNewEntryWithTrimmedMemo() {
            val draft = expenseDraft().copy(memo = "  ランチ \n")
            val now = Instant.ofEpochSecond(1_791_000_000)

            val entry = draft.newEntry(now)

            assertEquals("ランチ", entry.memo)
            assertEquals(now, entry.createdAt)
            assertEquals(now, entry.updatedAt)
        }

        @Test
        fun dropsBlankMemoAndDestinationOutsideTransfer() {
            val draft = expenseDraft().copy(
                memo = "   ",
                toWalletId = Identifier(),
            )

            val entry = draft.newEntry(Instant.now())

            assertNull(entry.memo)
            assertNull(entry.toWalletId)
        }

        @Test
        fun keepsCreationAndRecurringWhenApplied() {
            val created = Instant.ofEpochSecond(1_790_000_000)
            val now = Instant.ofEpochSecond(1_791_000_000)
            val recurringDate = date("2026-09-27")
            val recurringId = Identifier<Recurring>()
            val draft = expenseDraft()

            val original = Entry(
                type = Entry.Kind.income,
                amount = 1,
                date = recurringDate,
                categoryId = draft.categoryId,
                walletId = draft.walletId,
                recurringId = recurringId,
                recurringDate = recurringDate,
                createdAt = created,
                updatedAt = created,
            )

            val updated = draft.applied(
                to = original,
                at = now,
            )

            assertEquals(original.id, updated.id)
            assertEquals(Entry.Kind.expense, updated.type)
            assertEquals(draft.amount, updated.amount)
            assertEquals(recurringId, updated.recurringId)
            assertEquals(created, updated.createdAt)
            assertEquals(now, updated.updatedAt)
        }

        @Test
        fun throwsFirstProblem() {
            val draft = expenseDraft().copy(
                amount = 0,
                categoryId = null,
            )

            val error = assertFailsWith<EntryDraft.ProblemException> {
                draft.newEntry(Instant.now())
            }

            assertEquals(EntryDraft.Problem.amountNotPositive, error.problem)
        }

        private fun expenseDraft(): EntryDraft = EntryDraft(
            type = Entry.Kind.expense,
            amount = 980,
            date = date("2026-10-01"),
            categoryId = Identifier(),
            walletId = Identifier(),
        )
    }
}

private fun date(text: String): LocalDate = assertNotNull(LocalDate.parse(text))

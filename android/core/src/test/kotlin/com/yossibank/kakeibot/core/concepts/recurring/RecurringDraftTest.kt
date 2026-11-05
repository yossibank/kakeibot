package com.yossibank.kakeibot.core.concepts.recurring

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
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
import kotlin.test.assertNotNull
import kotlin.test.assertNull

@RunWith(Enclosed::class)
class RecurringDraftTest {
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
            val wallet: Boolean,
            val toWallet: String? = null,
            val frequency: Recurring.Frequency,
            val month: Int,
            val day: Int,
            val closingDay: Int? = null,
            val startDate: LocalDate,
            val endDate: LocalDate? = null,
            val remindDaysBefore: Int? = null,
            val problems: List<RecurringDraft.Problem>,
        ) {
            override fun toString(): String = summary
        }

        @Test
        fun findsProblems() {
            val walletId = Identifier<Wallet>()

            val toWalletId = when (fixture.toWallet) {
                "same" -> walletId
                "other" -> Identifier()
                else -> null
            }

            val draft = RecurringDraft(
                type = fixture.type,
                amount = fixture.amount,
                categoryId = if (fixture.category) Identifier() else null,
                walletId = if (fixture.wallet) walletId else null,
                toWalletId = toWalletId,
                frequency = fixture.frequency,
                month = fixture.month,
                day = fixture.day,
                closingDay = fixture.closingDay,
                startDate = fixture.startDate,
                endDate = fixture.endDate,
                remindDaysBefore = fixture.remindDaysBefore,
            )

            assertEquals(fixture.problems, draft.problems)
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<DraftCase> = CoreFixture.cases("recurring/recurring-draft.json", DraftCase.serializer())
        }
    }

    @RunWith(Parameterized::class)
    class ClampsBillShiftOfRecurring(
        private val shift: Int,
        private val expected: Int,
    ) {
        @Test
        fun clampsBillShiftOfRecurring() {
            val now = Instant.ofEpochSecond(1_791_000_000)
            val draft = rentDraft().copy(billShift = shift)

            val recurring = draft.newRecurring(now)

            assertEquals(expected, recurring.billShift)
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0} -> {1}")
            fun cases(): List<Array<Int>> = listOf(
                arrayOf(-3, 0),
                arrayOf(5, 2),
            )
        }
    }

    class Making {
        @Test
        fun makesRecurringWithTrimmedMemo() {
            val now = Instant.ofEpochSecond(1_791_000_000)
            val draft = rentDraft().copy(memo = " 家賃 ")

            val recurring = draft.newRecurring(now)

            assertEquals("家賃", recurring.memo)
            assertNull(recurring.month)
            assertNull(recurring.generatedUntil)
            assertEquals(now, recurring.createdAt)
        }

        @Test
        fun keepsIdentityWhenApplied() {
            val created = Instant.ofEpochSecond(1_790_000_000)
            val now = Instant.ofEpochSecond(1_791_000_000)
            val generated = date("2026-03-27")
            val original = rentDraft().newRecurring(created).copy(generatedUntil = generated)

            val draft = RecurringDraft(original).copy(
                frequency = Recurring.Frequency.yearly,
                month = 4,
            )

            val updated = draft.applied(
                to = original,
                at = now,
            )

            assertEquals(original.id, updated.id)
            assertEquals(4, updated.month)
            assertEquals(generated, updated.generatedUntil)
            assertEquals(created, updated.createdAt)
            assertEquals(now, updated.updatedAt)
        }

        @Test
        fun keepsGeneratedDateWhenStartMovesEarlier() {
            val now = Instant.ofEpochSecond(1_791_000_000)
            val generated = date("2026-03-27")
            val earlier = date("2025-12-01")
            val later = date("2026-02-01")
            val original = rentDraft().newRecurring(now).copy(generatedUntil = generated)
            val draft = RecurringDraft(original)

            val moved = draft.copy(startDate = later).applied(
                to = original,
                at = now,
            )

            val earlierStart = draft.copy(startDate = earlier).applied(
                to = original,
                at = now,
            )

            assertEquals(generated, moved.generatedUntil)
            assertEquals(generated, earlierStart.generatedUntil)
        }

        @Test
        fun keepsDestinationOnlyForTransfer() {
            val now = Instant.ofEpochSecond(1_791_000_000)
            val card = Identifier<Wallet>()
            val draft = rentDraft().copy(toWalletId = card)

            val expense = draft.newRecurring(now)

            val transfer = draft.copy(
                type = Entry.Kind.transfer,
                categoryId = null,
            ).newRecurring(now)

            assertNull(expense.toWalletId)
            assertEquals(card, transfer.toWalletId)
            assertNull(transfer.categoryId)
        }

        @Test
        fun keepsClosingDayOnlyForTransfer() {
            val now = Instant.ofEpochSecond(1_791_000_000)
            val draft = rentDraft().copy(closingDay = 15)

            val expense = draft.newRecurring(now)

            val bill = draft.copy(
                type = Entry.Kind.transfer,
                categoryId = null,
                toWalletId = Identifier(),
            ).newRecurring(now)

            assertNull(expense.closingDay)
            assertEquals(78000, expense.amount)
            assertEquals(15, bill.closingDay)
            assertEquals(0, bill.amount)
        }

        @Test
        fun keepsBillShiftOnlyForExpense() {
            val now = Instant.ofEpochSecond(1_791_000_000)
            val draft = rentDraft().copy(billShift = 1)

            val expense = draft.newRecurring(now)

            val bill = draft.copy(
                type = Entry.Kind.transfer,
                categoryId = null,
                toWalletId = Identifier(),
            ).newRecurring(now)

            assertEquals(1, expense.billShift)
            assertEquals(0, bill.billShift)
        }
    }
}

private fun date(text: String): LocalDate = assertNotNull(LocalDate.parse(text))

private fun rentDraft(): RecurringDraft = RecurringDraft(
    type = Entry.Kind.expense,
    amount = 78000,
    categoryId = Identifier(),
    walletId = Identifier(),
    frequency = Recurring.Frequency.monthly,
    month = 1,
    day = 27,
    startDate = date("2026-01-01"),
)

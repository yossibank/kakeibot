package com.yossibank.kakeibot.core.concepts.entry

import com.yossibank.kakeibot.core.concepts.date.LocalDate
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
class EntryTemplateDraftTest {
    @RunWith(Parameterized::class)
    class FindsProblems(
        private val fixture: DraftCase,
    ) {
        @Serializable
        data class DraftCase(
            val summary: String,
            val name: String,
            val type: Entry.Kind,
            val amount: Int? = null,
            val category: Boolean,
            val wallet: Boolean,
            val problems: List<EntryTemplateDraft.Problem>,
        ) {
            override fun toString(): String = summary
        }

        @Test
        fun findsProblems() {
            val draft = EntryTemplateDraft(
                name = fixture.name,
                type = fixture.type,
                amount = fixture.amount,
                categoryId = if (fixture.category) Identifier() else null,
                walletId = if (fixture.wallet) Identifier() else null,
            )

            assertEquals(fixture.problems, draft.problems)
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<DraftCase> = CoreFixture.cases("entry/entry-template-draft.json", DraftCase.serializer())
        }
    }

    @RunWith(Parameterized::class)
    class ClampsBillShiftOfTemplate(
        private val shift: Int,
        private val expected: Int,
    ) {
        @Test
        fun clampsBillShiftOfTemplate() {
            val now = Instant.ofEpochSecond(1_791_000_000)
            val draft = lunchDraft().copy(billShift = shift)

            val template = draft.newTemplate(
                sortOrder = 0,
                at = now,
            )

            assertEquals(expected, template.billShift)
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0} -> {1}")
            fun cases(): List<Array<Int>> = listOf(
                arrayOf(-3, 0),
                arrayOf(1, 1),
                arrayOf(5, 2),
            )
        }
    }

    class Making {
        @Test
        fun makesTemplateWithTrimmedText() {
            val now = Instant.ofEpochSecond(1_791_000_000)

            val draft = lunchDraft().copy(
                name = " ランチ ",
                memo = "  ",
            )

            val template = draft.newTemplate(
                sortOrder = 2,
                at = now,
            )

            assertEquals("ランチ", template.name)
            assertNull(template.memo)
            assertEquals(2, template.sortOrder)
            assertEquals(now, template.createdAt)
        }

        @Test
        fun keepsIdentityWhenApplied() {
            val created = Instant.ofEpochSecond(1_790_000_000)
            val now = Instant.ofEpochSecond(1_791_000_000)

            val original = lunchDraft().newTemplate(
                sortOrder = 3,
                at = created,
            )

            val draft = EntryTemplateDraft(original).copy(amount = null)

            val updated = draft.applied(
                to = original,
                at = now,
            )

            assertEquals(original.id, updated.id)
            assertNull(updated.amount)
            assertEquals(3, updated.sortOrder)
            assertEquals(created, updated.createdAt)
            assertEquals(now, updated.updatedAt)
        }

        @Test
        fun makesEntryDraftOnlyWithAmount() {
            val date = assertNotNull(LocalDate.parse("2026-10-15"))

            val lunch = lunchDraft().newTemplate(
                sortOrder = 0,
                at = Instant.now(),
            )

            val noAmount = lunch.copy(amount = null)

            val draft = lunch.entryDraft(date)

            assertEquals(980, draft?.amount)
            assertEquals(date, draft?.date)
            assertEquals("社食", draft?.memo)
            assertNull(noAmount.entryDraft(date))
        }
    }
}

private fun lunchDraft(): EntryTemplateDraft = EntryTemplateDraft(
    name = "ランチ",
    type = Entry.Kind.expense,
    amount = 980,
    categoryId = Identifier(),
    walletId = Identifier(),
    memo = "社食",
)

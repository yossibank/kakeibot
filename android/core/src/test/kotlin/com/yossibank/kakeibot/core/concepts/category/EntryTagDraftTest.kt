package com.yossibank.kakeibot.core.concepts.category

import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.core.support.CoreFixture
import kotlinx.serialization.Serializable
import org.junit.Test
import org.junit.experimental.runners.Enclosed
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertNull

@RunWith(Enclosed::class)
class EntryTagDraftTest {
    @RunWith(Parameterized::class)
    class FindsProblems(
        private val fixture: DraftCase,
    ) {
        @Serializable
        data class DraftCase(
            val summary: String,
            val name: String,
            val others: List<String>? = null,
            val problems: List<EntryTagDraft.Problem>,
        ) {
            override fun toString(): String = summary
        }

        @Test
        fun findsProblems() {
            val draft = EntryTagDraft(name = fixture.name)
            val others = (fixture.others ?: emptyList()).map { EntryTagDraft(name = it) }

            assertEquals(fixture.problems, draft.problems(among = others))
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<DraftCase> = CoreFixture.cases("category/entry-tag-draft.json", DraftCase.serializer())
        }
    }

    class Making {
        @Test
        fun makesNewTagWithTrimmedName() {
            val now = Instant.ofEpochSecond(1_791_000_000)
            val categoryId = Identifier<EntryCategory>()
            val draft = EntryTagDraft(name = " 昼ごはん ")

            val tag = draft.newTag(
                categoryId = categoryId,
                sortOrder = 2,
                at = now,
            )

            assertEquals("昼ごはん", tag.name)
            assertEquals(categoryId, tag.categoryId)
            assertEquals(2, tag.sortOrder)
            assertEquals(now, tag.createdAt)
        }

        @Test
        fun restoresArchivedTagWhenApplied() {
            val created = Instant.ofEpochSecond(1_790_000_000)
            val now = Instant.ofEpochSecond(1_791_000_000)

            val tag = EntryTag(
                categoryId = Identifier(),
                name = "朝ごはん",
                sortOrder = 0,
                archivedAt = created,
                createdAt = created,
                updatedAt = created,
            )

            val draft = EntryTagDraft(tag).copy(name = "モーニング")

            val updated = draft.applied(
                to = tag,
                sortOrder = 3,
                at = now,
            )

            assertEquals(tag.id, updated.id)
            assertEquals("モーニング", updated.name)
            assertEquals(3, updated.sortOrder)
            assertNull(updated.archivedAt)
            assertEquals(created, updated.createdAt)
            assertEquals(now, updated.updatedAt)
        }
    }
}

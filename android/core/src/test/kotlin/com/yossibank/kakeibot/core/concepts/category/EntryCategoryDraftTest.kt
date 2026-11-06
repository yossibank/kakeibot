package com.yossibank.kakeibot.core.concepts.category

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
class EntryCategoryDraftTest {
    @RunWith(Parameterized::class)
    class FindsProblems(
        private val fixture: DraftCase,
    ) {
        @Serializable
        data class DraftCase(
            val summary: String,
            val name: String,
            val mark: FixtureMark,
            val color: String,
            val problems: List<DraftProblem>,
        ) {
            override fun toString(): String = summary
        }

        @Test
        fun findsProblems() {
            val draft = EntryCategoryDraft(
                kind = EntryCategory.Kind.expense,
                name = fixture.name,
                mark = fixture.mark.mark(),
                color = fixture.color,
            )

            assertEquals(fixture.problems, draft.problems)
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<DraftCase> = CoreFixture.cases("category/entry-category-draft.json", DraftCase.serializer())
        }
    }

    class Making {
        @Test
        fun makesIconWithOnlyTheChosenMark() {
            val now = Instant.ofEpochSecond(1_791_000_000)

            val draft = EntryCategoryDraft(
                kind = EntryCategory.Kind.expense,
                name = " 推し ",
                mark = IconDraft.Mark.Text(" 推し "),
                color = "#9C6ADE",
            )

            val icon = draft.newIcon(now)

            val category = draft.newCategory(
                iconId = icon.id,
                sortOrder = 12,
                at = now,
            )

            assertEquals("推し", icon.text)
            assertNull(icon.emoji)
            assertNull(icon.glyph)
            assertEquals("推し", category.name)
            assertEquals(icon.id, category.iconId)
            assertEquals(12, category.sortOrder)
        }

        @Test
        fun keepsIdentityWhenApplied() {
            val created = Instant.ofEpochSecond(1_790_000_000)
            val now = Instant.ofEpochSecond(1_791_000_000)

            val icon = Icon(
                emoji = "🍙",
                text = null,
                color = "#E07A5F",
                createdAt = created,
                updatedAt = created,
            )

            val category = EntryCategory(
                kind = EntryCategory.Kind.expense,
                name = "食費",
                iconId = icon.id,
                sortOrder = 3,
                createdAt = created,
                updatedAt = created,
            )

            val draft = EntryCategoryDraft(
                category = category,
                icon = icon,
            ).copy(
                name = "外食",
                mark = IconDraft.Mark.Glyph(Icon.Glyph.cafe),
            )

            val updatedIcon = draft.applied(
                to = icon,
                at = now,
            )

            val updatedCategory = draft.applied(
                to = category,
                at = now,
            )

            assertEquals(IconDraft.Mark.Emoji("🍙"), IconDraft.Mark.of(icon))
            assertEquals(icon.id, updatedIcon.id)
            assertEquals(Icon.Glyph.cafe, updatedIcon.glyph)
            assertNull(updatedIcon.emoji)
            assertEquals(created, updatedIcon.createdAt)
            assertEquals(category.id, updatedCategory.id)
            assertEquals("外食", updatedCategory.name)
            assertEquals(3, updatedCategory.sortOrder)
            assertEquals(now, updatedCategory.updatedAt)
        }
    }
}

package com.yossibank.kakeibot.core.concepts.entry

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.core.support.CoreFixture
import kotlinx.serialization.Serializable
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import java.time.Instant
import kotlin.test.assertEquals

@RunWith(Parameterized::class)
class EntryDayTest(
    private val fixture: DayCase,
) {
    @Serializable
    data class DayCase(
        val summary: String,
        val categories: List<CategoryItem>? = null,
        val entries: List<EntryItem>,
        val days: List<DaySummary>,
    ) {
        override fun toString(): String = summary
    }

    @Serializable
    data class CategoryItem(
        val id: String,
        val kind: EntryCategory.Kind,
        val sortOrder: Int,
    )

    @Serializable
    data class EntryItem(
        val id: String,
        val type: Entry.Kind,
        val amount: Int,
        val date: LocalDate,
        val categoryId: String? = null,
        val createdAt: String,
    )

    @Serializable
    data class DaySummary(
        val date: LocalDate,
        val expense: Int,
        val income: Int,
        val entryIds: List<String>,
    )

    @Test
    fun groupsEntriesByDay() {
        val entries = fixture.entries.map { item ->
            val createdAt = Instant.parse(item.createdAt)

            Entry(
                id = identifier(item.id),
                type = item.type,
                amount = item.amount,
                date = item.date,
                categoryId = item.categoryId?.let(::identifier),
                walletId = Identifier(),
                createdAt = createdAt,
                updatedAt = createdAt,
            )
        }

        val categories = (fixture.categories ?: emptyList()).associate { item ->
            val id = identifier<EntryCategory>(item.id)
            val date = Instant.ofEpochSecond(0)

            id to EntryCategory(
                id = id,
                kind = item.kind,
                name = "",
                iconId = Identifier(),
                sortOrder = item.sortOrder,
                createdAt = date,
                updatedAt = date,
            )
        }

        val days = EntryDay.grouping(
            entries = entries,
            categories = categories,
        )

        val summaries = days.map { day ->
            DaySummary(
                date = day.date,
                expense = day.expenseTotal,
                income = day.incomeTotal,
                entryIds = day.entries.map { it.id.toString() },
            )
        }

        val expected = fixture.days.map { day ->
            day.copy(entryIds = day.entryIds.map { identifier<Entry>(it).toString() })
        }

        assertEquals(expected, summaries)
    }

    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun cases(): List<DayCase> = CoreFixture.cases("entry/entry-day.json", DayCase.serializer())
    }
}

private fun <Owner> identifier(text: String): Identifier<Owner> = Identifier.parse(text) ?: error("ID が読めない: $text")

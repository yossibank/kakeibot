package com.yossibank.kakeibot.core.concepts.entry

import com.yossibank.kakeibot.core.support.CoreFixture
import kotlinx.serialization.Serializable
import org.junit.Test
import org.junit.experimental.runners.Enclosed
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import kotlin.test.assertEquals
import kotlin.test.assertTrue

@RunWith(Enclosed::class)
class EntrySearchTest {
    @RunWith(Parameterized::class)
    class MatchesWords(
        private val fixture: SearchCase,
    ) {
        @Serializable
        data class SearchCase(
            val summary: String,
            val query: String,
            val amount: Int,
            val texts: List<String>,
            val matches: Boolean,
        ) {
            override fun toString(): String = summary
        }

        @Test
        fun matchesWords() {
            val search = EntrySearch(fixture.query)

            val matches = search.matches(
                amount = fixture.amount,
                texts = fixture.texts,
            )

            assertEquals(fixture.matches, matches)
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<SearchCase> = CoreFixture.cases("entry/entry-search.json", SearchCase.serializer())
        }
    }

    @RunWith(Parameterized::class)
    class RemembersRecentWords(
        private val fixture: RecentCase,
    ) {
        @Serializable
        data class RecentCase(
            val summary: String,
            val recent: List<String>,
            val text: String,
            val result: List<String>,
        ) {
            override fun toString(): String = summary
        }

        @Test
        fun remembersRecentWords() {
            val result = EntrySearch.remembering(
                text = fixture.text,
                recent = fixture.recent,
            )

            assertEquals(fixture.result, result)
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<RecentCase> = CoreFixture.cases("entry/entry-search-recent.json", RecentCase.serializer())
        }
    }

    class Splitting {
        @Test
        fun splitsOnAnySpace() {
            val search = EntrySearch("  ランチ　財布 ")

            assertEquals(listOf("ランチ", "財布"), search.words)
            assertTrue(EntrySearch(" ").isEmpty)
        }
    }
}

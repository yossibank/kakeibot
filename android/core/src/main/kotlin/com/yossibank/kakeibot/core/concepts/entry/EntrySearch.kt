package com.yossibank.kakeibot.core.concepts.entry

import java.text.Normalizer
import java.util.Locale

@ConsistentCopyVisibility
data class EntrySearch private constructor(
    val words: List<String>,
) {
    val isEmpty: Boolean
        get() = words.isEmpty()

    fun matches(
        amount: Int,
        texts: List<String>,
    ): Boolean {
        val folded = texts.map(::fold)

        return words.all { word ->
            amount(word) == amount.toLong() || folded.any { it.contains(word) }
        }
    }

    companion object {
        const val recentLimit = 5

        private val amountMarks = setOf('¥', '\\', ',', '円')
        private val japanese = Locale.JAPAN
        private val spaces = Regex("\\p{IsWhite_Space}+")

        operator fun invoke(text: String): EntrySearch = EntrySearch(
            words = text.split(spaces)
                .filter { it.isNotEmpty() }
                .map(::fold),
        )

        fun remembering(
            text: String,
            recent: List<String>,
        ): List<String> {
            val trimmed = text.trim()

            if (trimmed.isEmpty()) {
                return recent
            }

            val others = recent.filter { it != trimmed }

            return (listOf(trimmed) + others).take(recentLimit)
        }

        private fun fold(text: String): String = Normalizer.normalize(text, Normalizer.Form.NFKC).lowercase(japanese)

        private fun amount(word: String): Long? {
            val digits = word.filter { it !in amountMarks }

            if (digits.isEmpty() || !digits.all { it.code < 128 }) {
                return null
            }

            return digits.toLongOrNull()
        }
    }
}

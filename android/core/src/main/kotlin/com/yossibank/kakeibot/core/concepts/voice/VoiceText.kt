package com.yossibank.kakeibot.core.concepts.voice

import java.text.Normalizer

internal class VoiceText(
    raw: String,
) {
    val text: String = removingDigitCommas(Normalizer.normalize(raw, Normalizer.Form.NFKC))

    private val folded: String = fold(text)

    data class Span(
        val start: Int,
        val end: Int,
    ) {
        fun overlaps(other: Span): Boolean = start < other.end && other.start < end
    }

    data class Found<Value>(
        val value: Value,
        val range: Span,
    )

    fun contains(name: String): Boolean = range(of = name) != null

    fun range(of: String): Span? {
        val target = fold(of)

        if (target.isEmpty() || folded.length != text.length || target.length > folded.length) {
            val start = text.indexOf(of)
            return if (start < 0) null else Span(start, start + of.length)
        }

        val start = folded.indexOf(target)

        return if (start < 0) null else Span(start, start + target.length)
    }

    fun memo(removing: List<Span>): String? {
        val kept = StringBuilder()
        var index = 0

        for (range in removing.sortedBy { it.start }) {
            if (range.start < index) {
                continue
            }

            kept.append(text, index, range.start)
            kept.append(" ")
            index = range.end
        }

        kept.append(text, index, text.length)

        val fragments = split(kept.toString())
            .filter { it !in fillers && it !in endings }
            .map(::trimmed)
            .filter { it.isNotEmpty() && it !in payments }

        return if (fragments.isEmpty()) null else fragments.joinToString(" ")
    }

    internal companion object {
        private val separators: Set<Char> = "、。,.!?！？「」".toSet()
        private val particles: Set<Char> = "でにをはがともへの".toSet()

        private val endings = listOf(
            "の支払い",
            "支払い",
            "の料金",
            "の代金",
            "代金",
            "払いました",
            "払った",
            "買いました",
            "買った",
            "使いました",
            "使った",
            "でした",
            "です",
        )

        private val payments = setOf(
            "現金",
            "クレカ",
            "クレジット",
            "クレジットカード",
            "カード払い",
            "電子マネー",
            "現金払い",
        )

        private val fillers = setOf("えっと", "えーと", "えー", "あの", "あと", "それと", "から", "より")
        private val digitComma = Regex("([0-9])[,，](?=[0-9]{3})")

        fun fold(text: String): String {
            val katakana = buildString(text.length) {
                for (character in text) {
                    val code = character.code
                    val shifted = code in 0x3041..0x3096 || code in 0x309D..0x309E
                    append(if (shifted) (code + 0x60).toChar() else character)
                }
            }

            return katakana.lowercase()
        }

        private fun removingDigitCommas(text: String): String = text.replace(digitComma, "$1")

        private fun split(text: String): List<String> {
            val fragments = mutableListOf<String>()
            val current = StringBuilder()

            for (character in text) {
                if (character.isWhitespace() || character in separators) {
                    fragments += current.toString()
                    current.clear()
                } else {
                    current.append(character)
                }
            }

            fragments += current.toString()

            return fragments
        }

        private fun trimmed(fragment: String): String {
            var word = fragment
            val ending = endings.firstOrNull { word.endsWith(it) && word.length > it.length }

            if (ending != null) {
                word = word.dropLast(ending.length)
            }

            if (word.length > 1 && word.first() in particles) {
                word = word.drop(1)
            }

            if (word.length > 1 && word.last() in particles) {
                word = word.dropLast(1)
            }

            if (word.length == 1 && word.first() in particles) {
                return ""
            }

            return word
        }
    }
}

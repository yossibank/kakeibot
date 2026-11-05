package com.yossibank.kakeibot.core.concepts.icon

import com.yossibank.kakeibot.core.shared.DraftProblem
import com.yossibank.kakeibot.core.shared.DraftProblemException
import java.text.BreakIterator
import java.time.Instant

data class IconDraft(
    val mark: Mark,
    val color: String,
) {
    constructor(icon: Icon) : this(
        mark = Mark.of(icon),
        color = icon.color,
    )

    sealed interface Mark {
        data class Glyph(
            val glyph: Icon.Glyph,
        ) : Mark

        data class Emoji(
            val value: String,
        ) : Mark

        data class Text(
            val value: String,
        ) : Mark

        companion object {
            fun of(icon: Icon): Mark {
                val glyph = icon.glyph
                val emoji = icon.emoji

                return when {
                    glyph != null -> Glyph(glyph)
                    !emoji.isNullOrEmpty() -> Emoji(emoji)
                    else -> Text(icon.text ?: "")
                }
            }
        }
    }

    val problems: List<DraftProblem>
        get() {
            val colorProblems = if (isValidColor) emptyList() else listOf(DraftProblem.invalidColor)

            return markProblems + colorProblems
        }

    private val markProblems: List<DraftProblem>
        get() = when (mark) {
            is Mark.Glyph -> emptyList()

            is Mark.Emoji -> if (trimmed(mark.value).isEmpty()) listOf(DraftProblem.emptyMark) else emptyList()

            is Mark.Text -> {
                val trimmed = trimmed(mark.value)

                when {
                    trimmed.isEmpty() -> listOf(DraftProblem.emptyMark)
                    characterCount(trimmed) > MAX_TEXT_LENGTH -> listOf(DraftProblem.textTooLong)
                    else -> emptyList()
                }
            }
        }

    private val isValidColor: Boolean
        get() {
            val digits = color.drop(1)

            return color.startsWith("#") &&
                digits.length == 6 &&
                digits.all(::isHexDigit)
        }

    private val glyph: Icon.Glyph?
        get() = (mark as? Mark.Glyph)?.glyph

    private val emoji: String?
        get() = (mark as? Mark.Emoji)?.let { trimmed(it.value) }

    private val text: String?
        get() = (mark as? Mark.Text)?.let { trimmed(it.value) }

    fun newIcon(at: Instant): Icon {
        validate()

        return Icon(
            emoji = emoji,
            text = text,
            glyph = glyph,
            color = color,
            createdAt = at,
            updatedAt = at,
        )
    }

    fun applied(
        to: Icon,
        at: Instant,
    ): Icon {
        validate()

        return to.copy(
            emoji = emoji,
            text = text,
            glyph = glyph,
            color = color,
            updatedAt = at,
        )
    }

    private fun validate() {
        val problem = problems.firstOrNull() ?: return

        throw DraftProblemException(problem)
    }

    companion object {
        const val MAX_TEXT_LENGTH = 3

        private fun trimmed(value: String): String = value.trim()

        private fun isHexDigit(char: Char): Boolean =
            char in '0'..'9' ||
                char in 'a'..'f' ||
                char in 'A'..'F' ||
                char in '０'..'９' ||
                char in 'Ａ'..'Ｆ' ||
                char in 'ａ'..'ｆ'

        private fun characterCount(text: String): Int {
            val iterator = BreakIterator.getCharacterInstance()

            iterator.setText(text)

            var count = 0

            while (iterator.next() != BreakIterator.DONE) {
                count += 1
            }

            return count
        }
    }
}

package com.yossibank.kakeibot.core.concepts.theme

import com.yossibank.kakeibot.core.shared.DraftProblem
import com.yossibank.kakeibot.core.shared.DraftProblemException
import java.text.BreakIterator
import java.time.Instant

data class ThemeDraft(
    val name: String,
    val background: String,
    val surface: String,
    val text: String,
    val subtext: String,
    val accent: String,
) {
    constructor(
        name: String,
        palette: ThemePalette,
    ) : this(
        name = name,
        background = ThemeHex.text(palette.backgroundTop),
        surface = ThemeHex.text(palette.cardTop),
        text = ThemeHex.text(palette.text),
        subtext = ThemeHex.text(palette.subtext),
        accent = ThemeHex.text(palette.accent),
    )

    constructor(theme: Theme) : this(
        name = theme.name,
        background = theme.background,
        surface = theme.surface,
        text = theme.textPrimary,
        subtext = theme.textSecondary,
        accent = theme.accent,
    )

    val palette: ThemePalette?
        get() {
            val colors = listOf(background, surface, text, subtext, accent).mapNotNull(ThemeHex::rgb)

            if (colors.size != 5) {
                return null
            }

            return ThemePalette(
                background = colors[0],
                surface = colors[1],
                text = colors[2],
                subtext = colors[3],
                accent = colors[4],
            )
        }

    val problems: List<DraftProblem>
        get() {
            val palette = palette ?: return nameProblems + DraftProblem.invalidColor

            val isReadable = palette.unreadableRoles.isEmpty()

            return nameProblems + (if (isReadable) emptyList() else listOf(DraftProblem.unreadableColors))
        }

    fun newTheme(at: Instant): Theme {
        validate()

        return Theme(
            name = trimmedName,
            background = background,
            surface = surface,
            textPrimary = text,
            textSecondary = subtext,
            accent = accent,
            expense = expenseColor,
            income = accent,
            cornerRadius = cornerRadius,
            fontId = fontId,
            isBuiltin = false,
            createdAt = at,
            updatedAt = at,
        )
    }

    fun applied(
        to: Theme,
        at: Instant,
    ): Theme {
        validate()

        return to.copy(
            name = trimmedName,
            background = background,
            surface = surface,
            textPrimary = text,
            textSecondary = subtext,
            accent = accent,
            income = accent,
            updatedAt = at,
        )
    }

    private val trimmedName: String
        get() = name.trim()

    private val nameProblems: List<DraftProblem>
        get() =
            if (trimmedName.isEmpty()) {
                listOf(DraftProblem.emptyName)
            } else if (characterCount(trimmedName) > maxNameLength) {
                listOf(DraftProblem.nameTooLong)
            } else {
                emptyList()
            }

    private fun validate() {
        val problem = problems.firstOrNull()

        if (problem != null) {
            throw DraftProblemException(problem)
        }
    }

    companion object {
        val maxNameLength = 12

        private const val expenseColor = "#E3A3A3"
        private const val cornerRadius = 16
        private const val fontId = "system"

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

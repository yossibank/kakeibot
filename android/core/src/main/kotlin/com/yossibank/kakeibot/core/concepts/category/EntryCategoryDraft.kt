package com.yossibank.kakeibot.core.concepts.category

import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.icon.IconDraft
import com.yossibank.kakeibot.core.shared.DraftProblem
import com.yossibank.kakeibot.core.shared.DraftProblemException
import com.yossibank.kakeibot.core.shared.Identifier
import java.time.Instant

data class EntryCategoryDraft(
    val kind: EntryCategory.Kind,
    val name: String,
    val mark: IconDraft.Mark,
    val color: String,
) {
    constructor(
        category: EntryCategory,
        icon: Icon,
    ) : this(
        kind = category.kind,
        name = category.name,
        mark = IconDraft.Mark.of(icon),
        color = icon.color,
    )

    val icon: IconDraft
        get() = IconDraft(
            mark = mark,
            color = color,
        )

    val problems: List<DraftProblem>
        get() {
            val nameProblems = if (trimmedName.isEmpty()) listOf(DraftProblem.emptyName) else emptyList()

            return nameProblems + icon.problems
        }

    private val trimmedName: String
        get() = name.trim()

    fun newIcon(at: Instant): Icon {
        validate()

        return icon.newIcon(at)
    }

    fun newCategory(
        iconId: Identifier<Icon>,
        sortOrder: Int,
        at: Instant,
    ): EntryCategory {
        validate()

        return EntryCategory(
            kind = kind,
            name = trimmedName,
            iconId = iconId,
            sortOrder = sortOrder,
            createdAt = at,
            updatedAt = at,
        )
    }

    fun applied(
        to: Icon,
        at: Instant,
    ): Icon {
        validate()

        return icon.applied(
            to = to,
            at = at,
        )
    }

    fun applied(
        to: EntryCategory,
        at: Instant,
    ): EntryCategory {
        validate()

        return to.copy(
            name = trimmedName,
            updatedAt = at,
        )
    }

    private fun validate() {
        val problem = problems.firstOrNull() ?: return

        throw DraftProblemException(problem)
    }

    companion object {
        val maxTextLength = IconDraft.MAX_TEXT_LENGTH
    }
}

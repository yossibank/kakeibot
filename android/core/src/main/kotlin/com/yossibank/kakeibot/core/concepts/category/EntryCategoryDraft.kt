package com.yossibank.kakeibot.core.concepts.category

import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.icon.IconDraft
import com.yossibank.kakeibot.core.shared.DraftProblem
import com.yossibank.kakeibot.core.shared.IconHoldingDraft
import com.yossibank.kakeibot.core.shared.Identifier
import java.time.Instant

data class EntryCategoryDraft(
    val kind: EntryCategory.Kind,
    val name: String,
    val mark: IconDraft.Mark,
    val color: String,
) : IconHoldingDraft<EntryCategory> {
    constructor(
        category: EntryCategory,
        icon: Icon,
    ) : this(
        kind = category.kind,
        name = category.name,
        mark = IconDraft.Mark.of(icon),
        color = icon.color,
    )

    override fun newValue(
        iconId: Identifier<Icon>,
        sortOrder: Int,
        at: Instant,
    ): EntryCategory = newCategory(
        iconId = iconId,
        sortOrder = sortOrder,
        at = at,
    )

    override fun applied(
        to: EntryCategory,
        at: Instant,
    ): EntryCategory {
        validateProblems()

        return to.copy(
            name = trimmedName,
            updatedAt = at,
        )
    }

    override val icon: IconDraft
        get() = IconDraft(
            mark = mark,
            color = color,
        )

    override val problems: List<DraftProblem>
        get() {
            val nameProblems = if (trimmedName.isEmpty()) {
                listOf(
                    DraftProblem.emptyName,
                )
            } else {
                emptyList()
            }

            return nameProblems + icon.problems
        }

    fun newCategory(
        iconId: Identifier<Icon>,
        sortOrder: Int,
        at: Instant,
    ): EntryCategory {
        validateProblems()

        return EntryCategory(
            kind = kind,
            name = trimmedName,
            iconId = iconId,
            sortOrder = sortOrder,
            createdAt = at,
            updatedAt = at,
        )
    }

    private val trimmedName: String
        get() = name.trim()

    companion object {
        val maxTextLength = IconDraft.MAX_TEXT_LENGTH
    }
}

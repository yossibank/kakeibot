package com.yossibank.kakeibot.core.concepts.category

import com.yossibank.kakeibot.core.shared.Identifier
import kotlinx.serialization.Serializable
import java.text.BreakIterator
import java.time.Instant

data class EntryTagDraft(
    val id: Identifier<EntryTag>? = null,
    val name: String,
) {
    constructor(tag: EntryTag) : this(
        id = tag.id,
        name = tag.name,
    )

    @Serializable
    enum class Problem {
        emptyName,
        nameTooLong,
        duplicateName,
    }

    class ProblemException(
        val problem: Problem,
    ) : Exception(problem.name)

    val problems: List<Problem>
        get() {
            if (trimmedName.isEmpty()) {
                return listOf(Problem.emptyName)
            }

            return if (characterCount(trimmedName) > maxNameLength) listOf(Problem.nameTooLong) else emptyList()
        }

    private val trimmedName: String
        get() = name.trim()

    fun problems(among: List<EntryTagDraft>): List<Problem> {
        val own = problems

        if (own.isNotEmpty()) {
            return own
        }

        val isDuplicate = among.any { it.trimmedName == trimmedName }

        return if (isDuplicate) listOf(Problem.duplicateName) else emptyList()
    }

    fun newTag(
        categoryId: Identifier<EntryCategory>,
        sortOrder: Int,
        at: Instant,
    ): EntryTag {
        validate()

        return EntryTag(
            categoryId = categoryId,
            name = trimmedName,
            sortOrder = sortOrder,
            createdAt = at,
            updatedAt = at,
        )
    }

    fun applied(
        to: EntryTag,
        sortOrder: Int,
        at: Instant,
    ): EntryTag {
        validate()

        return to.copy(
            name = trimmedName,
            sortOrder = sortOrder,
            archivedAt = null,
            updatedAt = at,
        )
    }

    private fun validate() {
        val problem = problems.firstOrNull() ?: return

        throw ProblemException(problem)
    }

    companion object {
        val maxNameLength = 8

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

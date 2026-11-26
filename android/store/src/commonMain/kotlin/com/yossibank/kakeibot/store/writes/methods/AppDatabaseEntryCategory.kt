package com.yossibank.kakeibot.store.writes.methods

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.category.EntryCategoryDraft
import com.yossibank.kakeibot.core.concepts.category.EntryTag
import com.yossibank.kakeibot.core.concepts.category.EntryTagDraft
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.protocols.nextSortOrder
import com.yossibank.kakeibot.store.records.protocols.reorder
import com.yossibank.kakeibot.store.records.rows.BudgetRecord
import com.yossibank.kakeibot.store.records.rows.EntryCategoryRecord
import com.yossibank.kakeibot.store.records.rows.EntryTagRecord
import com.yossibank.kakeibot.store.records.rows.EntryTemplateRecord
import com.yossibank.kakeibot.store.records.rows.IconRecord
import com.yossibank.kakeibot.store.records.rows.RecurringRecord
import com.yossibank.kakeibot.store.records.rows.budget
import com.yossibank.kakeibot.store.records.rows.entryCategory
import com.yossibank.kakeibot.store.records.rows.entryTag
import com.yossibank.kakeibot.store.records.rows.entryTemplate
import com.yossibank.kakeibot.store.records.rows.icon
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.rows.recurring
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.writes.types.Deletion
import com.yossibank.kakeibot.store.writes.types.EntryCategoryTable
import java.time.Instant

enum class CategoryWriteError {
    categoryNotFound,
    iconNotFound,
    tagNotFound,
    hasEntries,
}

class CategoryWriteException(
    val error: CategoryWriteError,
) : Exception(error.name)

suspend fun AppDatabase.saveCategory(
    draft: EntryCategoryDraft,
    tags: List<EntryTagDraft>,
    editing: Identifier<EntryCategory>? = null,
    at: Instant,
): EntryCategory = write {
    val category = if (editing != null) {
        updateIconBacked(
            table = EntryCategoryTable,
            id = editing,
            with = draft,
            at = at,
        )
    } else {
        insertIconBacked(
            table = EntryCategoryTable,
            draft = draft,
            at = at,
        )
    }

    storeTags(
        drafts = tags,
        categoryId = category.id,
        at = at,
    )

    category
}

suspend fun AppDatabase.saveTags(
    drafts: List<EntryTagDraft>,
    categoryId: Identifier<EntryCategory>,
    at: Instant,
): List<EntryTag> = write {
    storeTags(
        drafts = drafts,
        categoryId = categoryId,
        at = at,
    )
}

suspend fun AppDatabase.deleteCategory(
    id: Identifier<EntryCategory>,
    at: Instant,
): Deletion = write {
    val category =
        findCategory(id) ?: throw CategoryWriteException(CategoryWriteError.categoryNotFound)

    val key = id.databaseValue

    if (entryDao().countOfCategory(key) > 0) {
        throw CategoryWriteException(CategoryWriteError.hasEntries)
    }

    val tags = tagDao().ofCategory(key).map { it.decoded(EntryTagRecord::entryTag) }
    val recurrings = recurringDao().ofCategory(key).map { it.decoded(RecurringRecord::recurring) }

    val templates = templateDao().ofCategory(key).map {
        it.decoded(EntryTemplateRecord::entryTemplate)
    }

    val budgets = budgetDao().ofCategory(key).map { it.decoded(BudgetRecord::budget) }

    val deletion = Deletion(
        categories = listOf(category),
        tags = tags,
        recurrings = recurrings,
        templates = templates,
        budgets = budgets,
    )

    deleteRecurrings(
        recurrings = recurrings,
        at = at,
    )

    templateDao().deleteOfCategory(key)
    budgetDao().deleteOfCategory(key)
    tagDao().deleteOfCategories(listOf(key))
    categoryDao().delete(key)

    deletion
}

private suspend fun AppDatabase.findCategory(id: Identifier<EntryCategory>): EntryCategory? =
    categoryDao().find(id.databaseValue)?.decoded(EntryCategoryRecord::entryCategory)

private suspend fun AppDatabase.storeTags(
    drafts: List<EntryTagDraft>,
    categoryId: Identifier<EntryCategory>,
    at: Instant,
): List<EntryTag> {
    val existing = tagDao().ofCategory(categoryId.databaseValue).map {
        it.decoded(EntryTagRecord::entryTag)
    }

    val names = drafts.map { it.name.trim() }

    if (names.toSet().size != names.size) {
        throw EntryTagDraft.ProblemException(EntryTagDraft.Problem.duplicateName)
    }

    val restorable = existing
        .filter { it.archivedAt != null }
        .sortedWith(
            compareBy(
                { it.createdAt },
                { it.id.toString() },
            ),
        )
        .toMutableList()

    val restored = drafts.zip(names).map { (draft, name) ->
        if (draft.id != null) {
            return@map draft
        }

        val index = restorable.indexOfFirst { it.name == name }

        if (index < 0) {
            return@map draft
        }

        draft.copy(id = restorable.removeAt(index).id)
    }

    val kept = restored.mapNotNull { it.id }.toSet()

    for (tag in existing) {
        if (tag.id in kept || tag.archivedAt != null) {
            continue
        }

        val archived = tag.copy(
            archivedAt = at,
            updatedAt = at,
        )

        tagDao().update(archived.record())
    }

    return restored.mapIndexed { order, draft ->
        val id = draft.id

        if (id == null) {
            val tag = draft.newTag(
                categoryId = categoryId,
                sortOrder = order,
                at = at,
            )

            tagDao().insert(tag.record())

            return@mapIndexed tag
        }

        val tag =
            existing.firstOrNull { it.id == id }
                ?: throw CategoryWriteException(CategoryWriteError.tagNotFound)

        val saved = draft.applied(
            to = tag,
            sortOrder = order,
            at = at,
        )

        tagDao().update(saved.record())

        saved
    }
}

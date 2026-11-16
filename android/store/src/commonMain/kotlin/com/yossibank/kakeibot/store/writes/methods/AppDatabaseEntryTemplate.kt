package com.yossibank.kakeibot.store.writes.methods

import com.yossibank.kakeibot.core.concepts.entry.EntryTemplate
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplateDraft
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.protocols.nextSortOrder
import com.yossibank.kakeibot.store.records.protocols.reorder
import com.yossibank.kakeibot.store.records.rows.EntryRecord
import com.yossibank.kakeibot.store.records.rows.EntryTemplateRecord
import com.yossibank.kakeibot.store.records.rows.entry
import com.yossibank.kakeibot.store.records.rows.entryTemplate
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.writes.types.Deletion
import java.time.Instant

enum class TemplateWriteError {
    templateNotFound,
    tagMismatch,
}

class TemplateWriteException(
    val error: TemplateWriteError,
) : Exception(error.name)

suspend fun AppDatabase.saveTemplate(
    draft: EntryTemplateDraft,
    editing: Identifier<EntryTemplate>? = null,
    at: Instant,
): EntryTemplate = write {
    val existing = editing?.let { findTemplate(it) ?: throw TemplateWriteException(TemplateWriteError.templateNotFound) }

    val template = if (existing != null) {
        draft.applied(
            to = existing,
            at = at,
        )
    } else {
        draft.newTemplate(
            sortOrder = nextSortOrder(templateDao().maxSortOrder()),
            at = at,
        )
    }

    val belongs = tag(
        id = template.tagId,
        belongsTo = template.categoryId,
    )

    if (!belongs) {
        throw TemplateWriteException(TemplateWriteError.tagMismatch)
    }

    if (existing != null) {
        templateDao().update(template.record())
    } else {
        templateDao().insert(template.record())
    }

    template
}

suspend fun AppDatabase.setTemplateHidden(
    id: Identifier<EntryTemplate>,
    isHidden: Boolean,
    at: Instant,
) {
    write {
        val template = findTemplate(id) ?: throw TemplateWriteException(TemplateWriteError.templateNotFound)

        val updated = template.copy(
            archivedAt = if (isHidden) at else null,
            updatedAt = at,
        )

        templateDao().update(updated.record())
    }
}

suspend fun AppDatabase.deleteTemplate(id: Identifier<EntryTemplate>): Deletion = write {
    val key = id.databaseValue
    val templates = listOfNotNull(findTemplate(id))
    val entries = entryDao().ofTemplate(key).map { it.decoded(EntryRecord::entry) }

    val deletion = Deletion(
        templates = templates,
        entries = entries,
    )

    templateDao().delete(key)

    deletion
}

suspend fun AppDatabase.reorderTemplates(
    ids: List<Identifier<EntryTemplate>>,
    at: Instant,
) {
    write {
        reorder(
            table = "template",
            ids = ids.map { it.databaseValue },
            notFound = TemplateWriteException(TemplateWriteError.templateNotFound),
            now = at,
        )
    }
}

private suspend fun AppDatabase.findTemplate(id: Identifier<EntryTemplate>): EntryTemplate? =
    templateDao().find(id.databaseValue)?.decoded(EntryTemplateRecord::entryTemplate)

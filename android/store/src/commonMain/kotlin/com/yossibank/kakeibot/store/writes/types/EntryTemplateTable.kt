package com.yossibank.kakeibot.store.writes.types

import com.yossibank.kakeibot.core.concepts.entry.EntryTemplate
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.records.protocols.ArchivableTable
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.EntryTemplateRecord
import com.yossibank.kakeibot.store.records.rows.entryTemplate
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.writes.methods.TemplateWriteError
import com.yossibank.kakeibot.store.writes.methods.TemplateWriteException
import java.time.Instant

object EntryTemplateTable : ArchivableTable<EntryTemplate> {
    override val name = "template"

    override fun notFound(): Throwable = TemplateWriteException(TemplateWriteError.templateNotFound)

    override suspend fun find(
        database: AppDatabase,
        id: Identifier<EntryTemplate>,
    ): EntryTemplate? =
        database.templateDao().find(id.databaseValue)?.decoded(EntryTemplateRecord::entryTemplate)

    override suspend fun update(
        database: AppDatabase,
        value: EntryTemplate,
    ) = database.templateDao().update(value.record())

    override fun archived(
        value: EntryTemplate,
        archivedAt: Instant?,
        at: Instant,
    ): EntryTemplate = value.copy(
        archivedAt = archivedAt,
        updatedAt = at,
    )
}

package com.yossibank.kakeibot.store.queries.methods

import com.yossibank.kakeibot.core.concepts.entry.EntryTemplate
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.observation
import com.yossibank.kakeibot.store.database.read
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.EntryTemplateRecord
import com.yossibank.kakeibot.store.records.rows.entryTemplate
import kotlinx.coroutines.flow.Flow

fun AppDatabase.templateUpdates(includingHidden: Boolean = false): Flow<List<EntryTemplate>> = observation("template") {
    fetchTemplates(includingHidden)
}

suspend fun AppDatabase.templates(includingHidden: Boolean = false): List<EntryTemplate> = read {
    fetchTemplates(includingHidden)
}

private suspend fun AppDatabase.fetchTemplates(includingHidden: Boolean): List<EntryTemplate> {
    val records = if (includingHidden) templateDao().inOrder() else templateDao().unarchivedInOrder()

    return records.map { it.decoded(EntryTemplateRecord::entryTemplate) }
}

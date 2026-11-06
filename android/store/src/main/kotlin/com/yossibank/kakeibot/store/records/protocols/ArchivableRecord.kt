package com.yossibank.kakeibot.store.records.protocols

interface ArchivableRecord : SortableRecord {
    val archivedAt: String?
}

fun <Record : ArchivableRecord> List<Record>.unarchivedInOrder(): List<Record> = filter { it.archivedAt == null }
    .sortedBy { it.sortOrder }

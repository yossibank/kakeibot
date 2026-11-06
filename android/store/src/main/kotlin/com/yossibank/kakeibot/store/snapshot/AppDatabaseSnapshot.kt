package com.yossibank.kakeibot.store.snapshot

import com.yossibank.kakeibot.core.concepts.export.v1.ExportV1
import com.yossibank.kakeibot.core.concepts.export.v1.csv
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.read
import com.yossibank.kakeibot.store.database.write
import java.time.Instant

suspend fun AppDatabase.snapshot(): ExportV1.Tables = read {
    fetchTables()
}

suspend fun AppDatabase.replace(with: ExportV1.Tables) {
    write {
        replaceTables(with)
    }
}

suspend fun AppDatabase.backup(
    at: Instant,
    app: ExportV1.App,
): ByteArray {
    val tables = snapshot()

    val export = ExportV1(
        exportedAt = at,
        app = app,
        data = tables,
    )

    return export.json()
}

suspend fun AppDatabase.spreadsheet(): ByteArray = snapshot().csv()

suspend fun AppDatabase.restoreBackup(
    export: ExportV1,
    stashingAt: Instant,
    app: ExportV1.App,
    stash: (ByteArray) -> Unit,
) {
    write {
        val current = ExportV1(
            exportedAt = stashingAt,
            app = app,
            data = fetchTables(),
        )

        stash(current.json())
        replaceTables(export.data)
    }
}

private suspend fun AppDatabase.replaceTables(tables: ExportV1.Tables) {
    deleteAllTables()
    tables.insert(this)
}

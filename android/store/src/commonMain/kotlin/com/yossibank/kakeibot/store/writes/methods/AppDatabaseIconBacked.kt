package com.yossibank.kakeibot.store.writes.methods

import com.yossibank.kakeibot.core.shared.IconBackedDraft
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.records.protocols.IconBackedTable
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.protocols.nextSortOrder
import com.yossibank.kakeibot.store.records.rows.IconRecord
import com.yossibank.kakeibot.store.records.rows.icon
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.values.databaseValue
import java.time.Instant

suspend fun <Value : Any, Draft : IconBackedDraft<Value>> AppDatabase.save(
    table: IconBackedTable<Value, Draft>,
    draft: Draft,
    editing: Identifier<Value>? = null,
    at: Instant,
): Value = write {
    if (editing != null) {
        updateIconBacked(
            table = table,
            id = editing,
            with = draft,
            at = at,
        )
    } else {
        insertIconBacked(
            table = table,
            draft = draft,
            at = at,
        )
    }
}

internal suspend fun <Value : Any, Draft : IconBackedDraft<Value>> AppDatabase.insertIconBacked(
    table: IconBackedTable<Value, Draft>,
    draft: Draft,
    at: Instant,
): Value {
    val icon = draft.newIcon(at)
    val sortOrder = nextSortOrder(table.maxSortOrder(this, draft))

    val value = draft.newValue(
        iconId = icon.id,
        sortOrder = sortOrder,
        at = at,
    )

    iconDao().insert(icon.record())
    table.insert(this, value)

    return value
}

internal suspend fun <Value : Any, Draft : IconBackedDraft<Value>> AppDatabase.updateIconBacked(
    table: IconBackedTable<Value, Draft>,
    id: Identifier<Value>,
    with: Draft,
    at: Instant,
): Value {
    val existing = table.find(this, id) ?: throw table.notFound()

    val icon = iconDao().find(table.iconId(existing).databaseValue)?.decoded(IconRecord::icon)
        ?: throw table.iconNotFound()

    val locked = table.locked(this, with, existing)

    val value = locked.applied(
        to = existing,
        at = at,
    )

    val updatedIcon = with.applied(
        to = icon,
        at = at,
    )

    iconDao().update(updatedIcon.record())
    table.update(this, value)

    return value
}

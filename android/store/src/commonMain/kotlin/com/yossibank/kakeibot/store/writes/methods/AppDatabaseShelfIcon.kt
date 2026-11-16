package com.yossibank.kakeibot.store.writes.methods

import com.yossibank.kakeibot.core.concepts.icon.IconDraft
import com.yossibank.kakeibot.core.concepts.icon.ShelfIcon
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.protocols.nextSortOrder
import com.yossibank.kakeibot.store.records.protocols.reorder
import com.yossibank.kakeibot.store.records.rows.IconRecord
import com.yossibank.kakeibot.store.records.rows.ShelfIconRecord
import com.yossibank.kakeibot.store.records.rows.icon
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.rows.shelfIcon
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.writes.types.Deletion
import java.time.Instant

enum class ShelfIconWriteError {
    shelfIconNotFound,
    iconNotFound,
}

class ShelfIconWriteException(
    val error: ShelfIconWriteError,
) : Exception(error.name)

suspend fun AppDatabase.saveShelfIcon(
    draft: IconDraft,
    editing: Identifier<ShelfIcon>? = null,
    at: Instant,
): ShelfIcon = write {
    if (editing != null) {
        updateShelfIcon(
            id = editing,
            with = draft,
            at = at,
        )
    } else {
        insertShelfIcon(
            draft = draft,
            at = at,
        )
    }
}

suspend fun AppDatabase.reorderShelfIcons(
    ids: List<Identifier<ShelfIcon>>,
    at: Instant,
) {
    write {
        reorder(
            table = "shelf_icon",
            ids = ids.map { it.databaseValue },
            notFound = ShelfIconWriteException(ShelfIconWriteError.shelfIconNotFound),
            now = at,
        )
    }
}

suspend fun AppDatabase.setShelfIconHidden(
    id: Identifier<ShelfIcon>,
    isHidden: Boolean,
    at: Instant,
) {
    write {
        val shelfIcon = findShelfIcon(id) ?: throw ShelfIconWriteException(ShelfIconWriteError.shelfIconNotFound)

        val updated = shelfIcon.copy(
            archivedAt = if (isHidden) at else null,
            updatedAt = at,
        )

        shelfIconDao().update(updated.record())
    }
}

suspend fun AppDatabase.deleteShelfIcon(id: Identifier<ShelfIcon>): Deletion = write {
    val shelfIcon = findShelfIcon(id) ?: throw ShelfIconWriteException(ShelfIconWriteError.shelfIconNotFound)

    shelfIconDao().delete(id.databaseValue)

    Deletion(shelfIcons = listOf(shelfIcon))
}

private suspend fun AppDatabase.findShelfIcon(id: Identifier<ShelfIcon>): ShelfIcon? =
    shelfIconDao().find(id.databaseValue)?.decoded(ShelfIconRecord::shelfIcon)

private suspend fun AppDatabase.insertShelfIcon(
    draft: IconDraft,
    at: Instant,
): ShelfIcon {
    val icon = draft.newIcon(at)
    val sortOrder = nextSortOrder(shelfIconDao().maxSortOrder())

    val shelfIcon = ShelfIcon(
        iconId = icon.id,
        sortOrder = sortOrder,
        createdAt = at,
        updatedAt = at,
    )

    iconDao().insert(icon.record())
    shelfIconDao().insert(shelfIcon.record())

    return shelfIcon
}

private suspend fun AppDatabase.updateShelfIcon(
    id: Identifier<ShelfIcon>,
    with: IconDraft,
    at: Instant,
): ShelfIcon {
    val shelfIcon = findShelfIcon(id) ?: throw ShelfIconWriteException(ShelfIconWriteError.shelfIconNotFound)

    val icon = iconDao().find(shelfIcon.iconId.databaseValue)?.decoded(IconRecord::icon)
        ?: throw ShelfIconWriteException(ShelfIconWriteError.iconNotFound)

    val updatedIcon = with.applied(
        to = icon,
        at = at,
    )

    iconDao().update(updatedIcon.record())

    val updated = shelfIcon.copy(updatedAt = at)

    shelfIconDao().update(updated.record())

    return updated
}

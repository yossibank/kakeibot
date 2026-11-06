package com.yossibank.kakeibot.store.queries.methods

import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.observation
import com.yossibank.kakeibot.store.database.read
import com.yossibank.kakeibot.store.queries.types.IconShelf
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.ShelfIconRecord
import com.yossibank.kakeibot.store.records.rows.shelfIcon
import kotlinx.coroutines.flow.Flow

fun AppDatabase.iconShelfUpdates(): Flow<IconShelf> = observation(
    "shelf_icon",
    "icon",
) {
    fetchIconShelf()
}

suspend fun AppDatabase.iconShelf(): IconShelf = read {
    fetchIconShelf()
}

private suspend fun AppDatabase.fetchIconShelf(): IconShelf {
    val shelfIcons = shelfIconDao()
        .inOrder()
        .map { it.decoded(ShelfIconRecord::shelfIcon) }

    return IconShelf(
        shelfIcons = shelfIcons,
        icons = fetchIcons(shelfIcons.map { it.iconId }),
    )
}

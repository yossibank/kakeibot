package com.yossibank.kakeibot.store.queries.methods

import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.observation
import com.yossibank.kakeibot.store.database.read
import com.yossibank.kakeibot.store.queries.types.ShelfIconList
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.ShelfIconRecord
import com.yossibank.kakeibot.store.records.rows.shelfIcon
import kotlinx.coroutines.flow.Flow

fun AppDatabase.shelfIconListUpdates(): Flow<ShelfIconList> = observation(
    "shelf_icon",
    "icon",
) {
    fetchShelfIconList()
}

suspend fun AppDatabase.shelfIconList(): ShelfIconList = read {
    fetchShelfIconList()
}

private suspend fun AppDatabase.fetchShelfIconList(): ShelfIconList {
    val shelfIcons = shelfIconDao()
        .inOrder()
        .map { it.decoded(ShelfIconRecord::shelfIcon) }

    return ShelfIconList(
        shelfIcons = shelfIcons,
        icons = fetchIcons(shelfIcons.map { it.iconId }),
    )
}

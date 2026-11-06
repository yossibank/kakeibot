package com.yossibank.kakeibot.store.queries.methods

import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.observation
import com.yossibank.kakeibot.store.database.read
import com.yossibank.kakeibot.store.queries.types.CategoryList
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.EntryCategoryRecord
import com.yossibank.kakeibot.store.records.rows.EntryTagRecord
import com.yossibank.kakeibot.store.records.rows.entryCategory
import com.yossibank.kakeibot.store.records.rows.entryTag
import kotlinx.coroutines.flow.Flow

fun AppDatabase.categoryListUpdates(): Flow<CategoryList> = observation(
    "category",
    "tag",
    "icon",
) {
    fetchCategoryList()
}

suspend fun AppDatabase.categoryList(): CategoryList = read {
    fetchCategoryList()
}

private suspend fun AppDatabase.fetchCategoryList(): CategoryList {
    val categories = categoryDao()
        .withoutWalletInOrder()
        .map { it.decoded(EntryCategoryRecord::entryCategory) }

    val tags = tagDao()
        .unarchivedWithoutWallet()
        .map { it.decoded(EntryTagRecord::entryTag) }

    return CategoryList(
        categories = categories,
        tags = tags,
        icons = fetchIcons(),
    )
}
